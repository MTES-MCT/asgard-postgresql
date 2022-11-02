"""Exécution multi-serveurs de la recette.

Ce module permet de lancer la recette d'Asgard sur un
ensemble de bases pré-définies, pour différentes versions de
PostgreSQL. Les bases et leur accès sont configurés via le
dictionnaire :py:data:`PG_DATABASES` ci-dessus.

Sous Windows, il est nécessaire de lancer les commandes en
tant qu'administrateur pour permettre la mise à jour des fichiers
de l'extension dans les répertoires dédiés des serveurs. À défaut
il faudra inhiber la mise à jour automatique, soit dans la 
configuration des bases, sans en exécutant la fonction
:py:fun:`run` avec un paramètre ``do_not_copy`` valant ``True``.

Exécution de la recette complète, pour toutes les versions
de PostgreSQL :

    >>> run()

Exécution de la recette pour une version donnée, ici
PostgreSQL 15 :

    >>> run('15')

... ou plusieurs versions :

    >>> run(['14', '15'])

En pratique, les opérations suivantes sont réalisées :

* copie des fichiers d'Asgard dans le répertoire des
  extensions du serveur, ie tous les fichiers .sql et
  .control à la racine du dépôt.
* activation des extensions nécessaires à l'exécution des
  tests sur la base cible.
* désactivation/réactivation d'Asgard dans la version
  considérée.
* création des fonctions de recette à partir de la
  dernière version du fichier ``recette/asgard_recette.sql``,
  dans un schéma ``asgard_recette``.
* exécution de la recette.

Pour chaque base testée, les erreurs rencontrées (ie les
fonctions qui ont échoué) sont affichées dans la console.

"""

import psycopg2
from psycopg2 import sql
from pathlib import Path
from contextlib import contextmanager

from recette import __path__ as recette_path

ASGARD_PATH = Path(recette_path[0]).parent

PG_DATABASES = [
    {
        'pg_version': '9.5',
        'port': '5431'
    },
    {
        'pg_version': '10',
        'port': '5432'
    },
    {
        'pg_version': '11',
        'port': '5433'
    },
    {
        'pg_version': '12',
        'port': '5434'
    },
    {
        'pg_version': '13',
        'port': '5435'
    },
    {
        'pg_version': '14',
        'port': '5436'
    },
    {
        'pg_version': '15',
        'port': '5437'
    }
]
"""Bases de tests.

``pg_version`` est le numéro de la version de PostgreSQL.

``host`` est l'adresse de l'hôte, par défaut ``'localhost'``.

``port`` est le port d'accès, par défaut ``'5432'``.

``dbname`` est le nom de la base de données, par défaut ``asgard_rec``.

``user`` est le nom du rôle de connexion super-utilisateur, par
défaut ``'postgres'``.

``password`` est le mot de passe de connexion. S'il n'est pas écrit
en clair dans cette liste (ce qui est a priori déconseillé), il sera
demandé dynamiquement d'abord un mot de passe général pour toutes les
connexions, puis, à défaut, un mot de passe par connexion.

``extension_dir`` est le chemin du répertoire où placer les fichiers
de l'extension pour que celle-ci puisse être activée sur la base. Si
non fourni, il est déduit du numéro de version, avec les règles
de nommage par défaut sous Windows.

``do_not_copy`` est un booléen. S'il est présent et vaut ``True``,
les fichiers de l'extension ne seront pas mis à jour d'après la
source. L'opération devra avoir été réalisée manuellement avant
l'exécution de la recette.

"""

class PgConnectionInfo():
    """Chaîne de connexion PostgreSQL.

    Parameters
    ----------
    pg_version : str, optional
        Numéro de la version de PostgreSQL.
    host : str, default 'localhost'
        Adresse de l'hôte.
    port : str, default '5432'
        Port d'accès.
    dbname : str, default 'asgard_rec'
        Nom de la base de données de recette.
    user : str, default 'postgres'
        Rôle de connexion à utiliser. Il doit s'agir d'un
        super-utilisateur.
    password : str, optional
        Mot de passe de connexion.
    extension_dir : str, optional
        Chemin du répertoire où placer les fichiers
        de l'extension pour que celle-ci puisse être activée
        sur la base. Si non fourni, il est déduit du numéro
        de version, avec les règles de nommage par défaut sous
        Windows.
    do_not_copy : bool, optional
        Si ``True``, les fichiers de l'extension ne seront pas
        mis à jour d'après la source. L'opération devra avoir été
        réalisée manuellement avant l'exécution de la recette.

    Attributes
    ----------
    pg_version : str
        Numéro de la version de PostgreSQL.
    host : str
        Adresse de l'hôte.
    port : str
        Port d'accès.
    dbname : str
        Nom de la base de données de recette.
    user : str
        Rôle de connexion.
    password : str
        Mot de passe de connexion.
    extension_dir : Path
        Chemin du répertoire où placer les fichiers
        de l'extension pour que celle-ci puisse être activée
        sur la base.

    """
    PASSWORD = None
    DATABASES = []

    def __init__(
        self, pg_version, host='localhost', port='5432', dbname='asgard_rec',
        user='postgres', password=None, extension_dir=None, do_not_copy=False
    ):
        self.pg_version = pg_version
        self.host = host
        self.port = port
        self.dbname = dbname
        self.user = user
        self.password = password
        self.extension_dir = None
        if not do_not_copy:
            self.extension_dir = Path(
                extension_dir or f'C:\\Program Files\\PostgreSQL\\{pg_version}\\share\\extension'
            )

    def __str__(self):
        return f'host={self.host} port={self.port} dbname={self.dbname} user={self.user} password={self.password}'

    @property
    def pretty(self):
        return f'< PostgreSQL {self.pg_version} - {self.host}:{self.port} {self.dbname} >'

    @classmethod
    def password(cls, password=None):
        """Définit un mot de passe par défaut pour toutes les connexions.
        
        Il est possible de passer cette étape en ne saisissant simplement
        aucune valeur avant de valider.

        """
        if not password:
            password = input('Mot de passe par défaut : ')
            if not password:
                return
        cls.PASSWORD = password

    @classmethod
    def add(
        cls, pg_version='', host='localhost', port='5432', dbname='asgard_rec',
        user='postgres', password=None
    ):
        """Génère et mémorise une nouvelle connexion.
        
        Si aucun mot de passe n'est fourni en argument et qu'il
        n'y avait pas non plus de mot de passe par défaut, il
        est redemandé dynamiquement.

        Parameters
        ----------
        pg_version : str, optional
            Numéro de la version de PostgreSQL.
        host : str, default 'localhost'
            Adresse de l'hôte.
        port : str, default '5432'
            Port d'accès.
        dbname : str, default 'asgard_rec'
            Nom de la base de données de recette.
        user : str, default 'postgres'
            Rôle de connexion. Il doit s'agir d'un
            super-utilisateur.
        password : str, optional
            Mot de passe de connexion.

        """
        password = password or cls.PASSWORD
        while not password:
            password = input(
                f'Mot de passe pour le rôle "{user}" sur '
                f'{host}:{port} ({pg_version}) ? '
            )
        cls.DATABASES.append(
            PgConnectionInfo(
                pg_version, host, port, dbname, user,
                password
            )
        )

    @classmethod
    def remove(cls, pg_connection_info):
        """Supprime une connexion de la liste des connexions mémorisées.

        La fonction n'a aucun effet si la connexion n'était
        pas référencée.
        
        Parameters
        ----------
        pg_connection_info : PgConnectionInfo
            La connexion à supprimer.
        
        """
        if pg_connection_info and pg_connection_info in cls.DATABASES:
            cls.DATABASES.remove(pg_connection_info)

    @classmethod
    def build(cls):
        """Mémorise les connexions pré-définies dans PG_DATABASES."""
        if not cls.PASSWORD:
            cls.password()
        for connection_dict in PG_DATABASES:
            cls.add(**connection_dict)
    
    @classmethod
    def databases(cls):
        """Générateur sur les connexions mémorisées."""
        if not cls.DATABASES:
            cls.build()
        for pg_connection_info in cls.DATABASES:
            yield pg_connection_info


def pg_test_functions(filepath=None):
    """Importe les commandes de création des fonctions PostgreSQL qui servent à la recette.
    
    Parameters
    ----------
    filepath : str or Path, optional
        Chemin complet du fichier source. Si non
        fourni, la fonction ira chercher le fichier
        ``recette/asgard_recette.sql``.
    
    Returns
    -------
    str
    
    """
    pfile = Path(filepath) if filepath else Path(recette_path[0]) / 'asgard_recette.sql'
    
    if not pfile.exists():
        raise FileNotFoundError("Can't find file {}.".format(pfile))
        
    if not pfile.is_file():
        raise TypeError("{} is not a file.".format(pfile))
    
    return pfile.read_text(encoding='UTF-8')

def copy_file(filepath, target_dir):
    """Copie un fichier ou plusieurs fichiers.

    Parameters
    ----------
    filepath : str or Path or list(str or Path), optional
        Chemin complet du fichier source. Il est possible
        de fournir une liste de chemins.
    target_dir : str or Path, optional
        Chemin complet du répertoire de destination.

    """
    if isinstance(filepath, list):
        for file in filepath:
            copy_file(file, target_dir)
    
    pfile = Path(filepath)

    if not pfile.exists():
        raise FileNotFoundError("Can't find file {}.".format(pfile))
        
    if not pfile.is_file():
        raise TypeError("{} is not a file.".format(pfile))
    
    pdir = Path(target_dir)

    if not pdir.exists():
        raise FileNotFoundError("Can't find directory {}.".format(pdir))
        
    if not pdir.is_dir():
        raise TypeError("{} is not a directory.".format(pdir))

    content = pfile.read_text(encoding='UTF-8')

    target_pfile = pdir / pfile.name
    target_pfile.write_text(content, encoding='UTF-8')

@contextmanager
def pg_connection(
    pg_connection_info, pg_test_functions,
    extension_name, extension_version=None,
    extension_requirements=None, test_requirements=None
):
    conn = psycopg2.connect(str(pg_connection_info))
    with conn:
        with conn.cursor() as cur:
            for extension in test_requirements or []:
                cur.execute(
                    sql.SQL(
                        '''
                        CREATE EXTENSION IF NOT EXISTS {} ;
                        '''
                    ).format(sql.Identifier(extension))
                )
            for extension in extension_requirements or []:
                cur.execute(
                    sql.SQL(
                        '''
                        CREATE EXTENSION IF NOT EXISTS {} ;
                        '''
                    ).format(sql.Identifier(extension))
                )
            if extension_version:
                cur.execute(
                    sql.SQL(
                        '''
                        DROP EXTENSION IF EXISTS {extension} ;
                        CREATE EXTENSION {extension} VERSION %s ;
                        '''
                    ).format(extension=sql.Identifier(extension_name)),
                    (extension_version,)
                )
            else:
                cur.execute(
                    sql.SQL(
                        '''
                        DROP EXTENSION IF EXISTS {extension} ;
                        CREATE EXTENSION {extension} ;
                        DROP SCHEMA IF EXISTS z_asgard_recette CASCADE ;
                        '''
                    ).format(extension=sql.Identifier(extension_name))
                )
            cur.execute(pg_test_functions)
    try:
        yield conn

    finally:
        conn.close()

def run(pg_versions=None, extension_version=None, do_not_copy=False):
    """Exécute la recette.

    Parameters
    ----------
    pg_versions : str or list(str), optional
        Numéros des versions pour lesquelles la recette doit être
        lancée. Si non spécifié, la recette est lancée sur toutes
        les bases de test listées par :py:data:`PG_DATABASES`.
    extension_version : str, optional
        Le numéro de la version de l'extension à tester. Si non
        spécifié, c'est la version par défaut du fichier
        ``asgard.control`` qui est considérée.
    do_not_copy : bool, default False
        Si ``True``, les fichiers de l'extension ne seront pas
        mis à jour avant exécution de la recette.
    
    """
    if isinstance(pg_versions, str):
        pg_versions = [pg_versions]

    kwargs = {
        'pg_test_functions': pg_test_functions(),
        'extension_name': 'asgard',
        'test_requirements': ['postgres_fdw']
        }
    if extension_version:
        kwargs['extension_version'] = extension_version

    for pg_connection_info in PgConnectionInfo.databases():
        if pg_versions and not pg_connection_info.pg_version in pg_versions:
            continue
        print('\n--------------')
        print(pg_connection_info.pretty)

        # mise à jour des fichiers de l'extension
        if not do_not_copy and pg_connection_info.extension_dir:
            for file in ASGARD_PATH.iterdir():
                if file.is_file() and file.suffix in ('.control', '.sql'):
                    copy_file(file, pg_connection_info.extension_dir)

        # exécution de la recette
        with pg_connection(pg_connection_info, **kwargs) as conn:
            with conn:
                with conn.cursor() as cur:
                    cur.execute(
                        '''
                        SELECT z_asgard_recette.count_tests() ;
                        '''
                    )
                    nb_tests = cur.fetchone()[0]
                    cur.execute(
                        '''
                        SELECT * FROM z_asgard_recette.execute_recette() ;
                        '''
                    )
                    failures = cur.fetchall()
        if failures:
            print('... {} tests, {} erreurs'.format(nb_tests, len(failures)))
            for failure in failures:
                print(f'{failure[0]}: {failure[1]}')
        else:
            print(f'... {nb_tests} tests, aucune erreur')

if __name__ == '__main__':
    run()