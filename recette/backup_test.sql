-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
--
-- ASGARD - Système de gestion des droits pour PostgreSQL
-- > Script de test de sauvegarde/restauration.
--
-- Copyright République Française, 2020-2025.
-- Secrétariat général des ministères en charge de l'aménagement du 
-- territoire et de la transition écologique.
-- Direction du Numérique.
--
-- contributrice pour cette version : Leslie Lemaire (DNUM/UNI/DRC).
-- 
-- mél : drc.uni.dnum.sg@developpement-durable.gouv.fr
--
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
--
-- À exécuter sur une base vierge.
--
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

/*

Les rôles d'Asgard g_admin et g_consult doivent pré-exister sur le ou 
les serveurs utilisés lors du test.

1. Exécuter le présent script sur une base asgard_dump vierge. 
   g_admin doit avoir le privilège CREATE avec l'option ADMIN sur 
   cette base.

> GRANT CREATE ON DATABASE asgard_dump TO g_admin WITH GRANT OPTION ;

2. Sauvegarder cette base.

3. Créer une nouvelle base asgard_restore, le cas échéant sur un autre
   serveur, et donner à g_admin le privilège CREATE avec ADMIN OPTION sur
   cette base.

> GRANT CREATE ON DATABASE asgard_restore TO g_admin WITH GRANT OPTION ;

4. Restaurer la base. Il ne doit y avoir aucune erreur.

5. Exécuter la fonction de contrôle. Elle renvoie True si l'état de la base 
restaurée est conforme à ce qui était attendu, sinon une erreur.

SELECT asgard_backup_restore_control() ;

6. Supprimer les bases de test.

*/

CREATE SCHEMA c_citadelle ;

CREATE EXTENSION asgard ;

CREATE SCHEMA c_bibliotheque AUTHORIZATION g_admin ;

UPDATE z_asgard.gestion_schema_usr
    SET lecteur = 'g_consult'
    WHERE nom_schema = 'c_bibliotheque' ;

INSERT INTO z_asgard.gestion_schema_usr (nom_schema, producteur, creation, editeur) 
    VALUES ('c_librairie', 'g_asgard_ghost', False, 'g_admin') ;

INSERT INTO z_asgard_admin.asgard_configuration VALUES ('autorise_objets_inconnus') ;


------ Fonction de contrôle ------

-- Function: asgard_backup_restore_control()

CREATE OR REPLACE FUNCTION asgard_backup_restore_control()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
BEGIN

    ASSERT 'autorise_objets_inconnus' IN (
        SELECT parametre FROM z_asgard_admin.asgard_configuration
    ), 'échec assertion 1 - préservation du contenu de la table de configuration' ;

    ASSERT 'c_citadelle' IN (
        SELECT nspname FROM pg_catalog.pg_namespace
    ), 'échec assertion 2 - préservation du schéma c_citadelle' ;

    ASSERT NOT 'c_citadelle' IN (
        SELECT nom_schema FROM z_asgard_admin.gestion_schema
    ), 'échec assertion 3 - préservation du non référencement de c_citadelle' ;

    ASSERT 'c_bibliotheque' IN (
        SELECT nspname FROM pg_catalog.pg_namespace
    ), 'échec assertion 4 - préservation du schéma c_bibliotheque' ;

    ASSERT 'c_bibliotheque' IN (
        SELECT nom_schema 
            FROM z_asgard_admin.gestion_schema
    ), 'échec assertion 5 - préservation du référencement de c_bibliotheque' ;

    ASSERT 'g_admin' = (
        SELECT producteur 
            FROM z_asgard_admin.gestion_schema
            WHERE nom_schema = 'c_bibliotheque'
    ), 'échec assertion 6 - préservation du producteur de c_bibliotheque' ;

    ASSERT 'g_consult' = (
        SELECT lecteur 
            FROM z_asgard_admin.gestion_schema
            WHERE nom_schema = 'c_bibliotheque'
    ), 'échec assertion 7 - préservation du lecteur de c_bibliotheque' ;

    ASSERT 'c_bibliotheque'::regnamespace::int = (
        SELECT oid_schema::int
            FROM z_asgard_admin.gestion_schema
            WHERE nom_schema = 'c_bibliotheque'
    ), 'échec assertion 8 - validité de l''OID du schéma' ;

    ASSERT 'g_admin'::regrole::int = (
        SELECT oid_producteur::int
            FROM z_asgard_admin.gestion_schema
            WHERE nom_schema = 'c_bibliotheque'
    ), 'échec assertion 9 - validité de l''OID du producteur' ;

    ASSERT (
        SELECT creation 
            FROM z_asgard_admin.gestion_schema
            WHERE nom_schema = 'c_bibliotheque'
    ), 'échec assertion 10 - c_bibliotheque est toujours marqué comme actif' ;

    ASSERT NOT 'c_librairie' IN (
        SELECT nspname FROM pg_catalog.pg_namespace
    ), 'échec assertion 11 - préservation de la non existence du schéma c_librairie' ;

    ASSERT 'c_librairie' IN (
        SELECT nom_schema 
            FROM z_asgard_admin.gestion_schema
    ), 'échec assertion 12 - préservation du référencement de c_librairie' ;

    ASSERT NOT (
        SELECT creation 
            FROM z_asgard_admin.gestion_schema
            WHERE nom_schema = 'c_librairie'
    ), 'échec assertion 13 - c_librairie est toujours marqué comme inactif' ;

    ASSERT 'g_asgard_ghost' = (
        SELECT producteur 
            FROM z_asgard_admin.gestion_schema
            WHERE nom_schema = 'c_librairie'
    ), 'échec assertion 14 - préservation du producteur de c_librairie' ;

    ASSERT 'g_admin' = (
        SELECT editeur 
            FROM z_asgard_admin.gestion_schema
            WHERE nom_schema = 'c_librairie'
    ), 'échec assertion 15 - préservation de l''écteur de c_librairie' ;

    ASSERT NOT 'g_asgard_ghost' IN (
        SELECT
            rolname FROM pg_catalog.pg_roles
    ), 'échec assertion 16 - préservation de la non existance du rôle g_asgard_ghost' ;

    RETURN True ;
    
END
$_$;

COMMENT ON FUNCTION asgard_backup_restore_control() IS 'ASGARD recette. TEST : Contrôle d''intégrité après restauration d''une base.' ;
