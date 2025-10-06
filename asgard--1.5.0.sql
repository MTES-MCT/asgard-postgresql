\echo Use "CREATE EXTENSION asgard" to load this file. \quit
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
--
-- ASGARD - Système de gestion des droits pour PostgreSQL, version 1.5.0
--
-- Copyright République Française, 2020-2025.
-- Secrétariat général des ministères en charge de l'aménagement du 
-- territoire et de la transition écologique.
-- Direction du Numérique.
--
-- contributeurs : Leslie Lemaire (DNUM/UNI/DRC) et Alain Ferraton
-- (DNUM/MSP/DS/GSG).
-- 
-- mél : drc.uni.dnum.sg@developpement-durable.gouv.fr
--
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
--
-- Documentation :
-- https://snum.scenari-community.org/Asgard/Documentation
-- 
-- GitHub :
-- https://github.com/MTES-MCT/asgard-postgresql
--
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
--
-- Ce logiciel est un programme informatique complémentaire au système de
-- gestion de base de données PosgreSQL ("https://www.postgresql.org/"). Il
-- met à disposition un cadre méthodologique et des outils pour la gestion
-- des droits sur les serveurs PostgreSQL.
--
-- Ce logiciel est régi par la licence CeCILL-B soumise au droit français
-- et respectant les principes de diffusion des logiciels libres. Vous
-- pouvez utiliser, modifier et/ou redistribuer ce programme sous les
-- conditions de la licence CeCILL-B telle que diffusée par le CEA, le
-- CNRS et l'INRIA sur le site "http://www.cecill.info".
-- Lien SPDX : "https://spdx.org/licenses/CECILL-B.html".
--
-- En contrepartie de l'accessibilité au code source et des droits de copie,
-- de modification et de redistribution accordés par cette licence, il n'est
-- offert aux utilisateurs qu'une garantie limitée.  Pour les mêmes raisons,
-- seule une responsabilité restreinte pèse sur l'auteur du programme,  le
-- titulaire des droits patrimoniaux et les concédants successifs.
--
-- A cet égard l'attention de l'utilisateur est attirée sur les risques
-- associés au chargement,  à l'utilisation,  à la modification et/ou au
-- développement et à la reproduction du logiciel par l'utilisateur étant 
-- donné sa spécificité de logiciel libre, qui peut le rendre complexe à 
-- manipuler et qui le réserve donc à des développeurs et des professionnels
-- avertis possédant  des  connaissances  informatiques approfondies.  Les
-- utilisateurs sont donc invités à charger  et  tester  l'adéquation  du
-- logiciel à leurs besoins dans des conditions permettant d'assurer la
-- sécurité de leurs systèmes et ou de leurs données et, plus généralement, 
-- à l'utiliser et l'exploiter dans les mêmes conditions de sécurité. 
--
-- Le fait que vous puissiez accéder à cet en-tête signifie que vous avez 
-- pris connaissance de la licence CeCILL-B, et que vous en avez accepté
-- les termes.
--
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
--
-- Cette extension ne peut être installée que par un super-utilisateur
-- (création de déclencheurs sur évènement).
--
-- <!> Un rôle dénommé "g_admin" doit avoir été créé avant l'activation de
-- l'extension et disposer du privilège CREATE avec l'option GRANT sur
-- la base courante. Ce rôle sera rendu membre de tous les rôles créés par
-- l'extension Asgard avec l'option ADMIN. Il dispose plus généralement de
-- privilèges étendus sur tous les objets de l'extension.
--
-- Elle n'est pas compatible avec les versions 9.4 ou antérieures de
-- PostgreSQL.
--
-- Schémas contenant les objets : z_asgard et z_asgard_admin.
--
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

/* 1 - PREPARATION DES ROLES
   2 - PREPARATION DES OBJETS
   3 - FONCTIONS UTILITAIRES
   4 - CREATION DES EVENT TRIGGERS
   5 - TRIGGERS SUR GESTION_SCHEMA
   6 - GESTION DES PERMISSIONS SUR LAYER_STYLES */

-- MOT DE PASSE DE CONTRÔLE : 'x7-A;#rzo'

---------------------------------------
------ 1 - PREPARATION DES ROLES ------
---------------------------------------
/* 1.1 - CREATION DES NOUVEAUX ROLES
   1.2 - AJUSTEMENTS DIVERS SUR LES PRIVILEGES */


------ 1.1 - CREATION DES NOUVEAUX ROLES ------

DO
$$
DECLARE
    g_admin_info record ;
BEGIN

    -- Role: g_admin

    -- g_admin doit exister et disposer du privilège CREATE sur la base
    -- courante avec l'option GRANT. S'il ne les avait pas déjà, il recevra
    -- les attributs CREATEROLE et INHERIT. Il est recommandé de lui donner
    -- aussi les attributs CREATEDB et BYPASSRLS, et déconseillé d'en faire
    -- un super-utilisateur (SUPERUSER) ou un rôle de connexion (LOGIN).

    SELECT rolcreaterole, rolcanlogin, rolinherit
        INTO g_admin_info
        FROM pg_catalog.pg_roles
        WHERE rolname = 'g_admin' ;
       
    IF NOT FOUND OR NOT 'g_admin' IN (
        SELECT acl.grantee::regrole::text
            FROM pg_catalog.pg_database,
                aclexplode(datacl) AS acl (grantor, grantee, privilege, grantable)
            WHERE datname = current_database()
                AND acl.privilege = 'CREATE'
                AND acl.grantable
    ) 
    THEN
    
        RAISE EXCEPTION 'Echec de l''activation d''Asgard. Un rôle dénommé g_admin et disposant du privilège CREATE sur la base courante avec l''option GRANT doit pré-exister.'
            USING HINT = format(
                    'Exemple de commandes permettant la création d''un tel rôle : 
> CREATE ROLE g_admin CREATEROLE CREATEDB BYPASSRLS ; 
> GRANT CREATE ON DATABASE %I TO g_admin WITH GRANT OPTION ;',
                    current_database()
                ),
                ERRCODE = 'invalid_role_specification' ;
        
    ELSE
        IF NOT g_admin_info.rolcreaterole
        THEN
        
            RAISE NOTICE '... Octroi de l''attribut CREATEROLE au rôle g_admin.' ;
            ALTER ROLE g_admin WITH CREATEROLE ;
            
        END IF ;

        IF NOT g_admin_info.rolinherit
        THEN
        
            RAISE NOTICE '... Octroi de l''attribut INHERIT au rôle g_admin.' ;
            ALTER ROLE g_admin WITH INHERIT ;
            
        END IF ;

        IF g_admin_info.rolcanlogin
        THEN
        
            RAISE WARNING 'Pour le bon fonctionnement d''ASGARD, le rôle g_admin ne doit en aucun cas être un rôle de connexion.'
                USING HINT = 'Pour lui retirer l''attribut LOGIN, vous pouvez exécuter la requête suivante : 
> ALTER ROLE g_admin NOLOGIN ;' ;
        
        END IF ;
    END IF ;

    -- Role: g_admin_ext

    IF NOT 'g_admin_ext' IN (SELECT rolname FROM pg_catalog.pg_roles)
    THEN
    
        CREATE ROLE g_admin_ext ;
          
        COMMENT ON ROLE g_admin_ext IS 'Rôle technique réservé à g_admin.' ;
        
    END IF ;
    
    IF NOT 'g_admin' IN (
        SELECT pg_auth_members.member::regrole::text 
            FROM pg_auth_members
            WHERE pg_auth_members.roleid::regrole::text = 'g_admin_ext'
                AND pg_auth_members.admin_option
    )
    THEN
    
        -- g_admin est rendu membre de g_admin_ext avec
        -- l'option ADMIN s'il ne l'est pas déjà.
        GRANT g_admin_ext TO g_admin WITH ADMIN OPTION ;
        
    END IF ;
  
    -- Role: g_consult

    IF NOT 'g_consult' IN (SELECT rolname FROM pg_catalog.pg_roles)
    THEN
    
        CREATE ROLE g_consult ;
          
        COMMENT ON ROLE g_consult IS 'Rôle de consultation des données publiques (accès aux données en lecture seule).' ;
        
    END IF ;

    IF NOT 'g_admin' IN (
        SELECT pg_auth_members.member::regrole::text 
            FROM pg_auth_members
            WHERE pg_auth_members.roleid::regrole::text = 'g_consult'
                AND pg_auth_members.admin_option
    )
    THEN
    
        -- g_admin est rendu membre de g_consult avec
        -- l'option ADMIN s'il ne l'est pas déjà.
        GRANT g_consult TO g_admin WITH ADMIN OPTION ;
        
    END IF ;

    -- Role: "consult.defaut"

    IF NOT 'consult.defaut' IN (SELECT rolname FROM pg_catalog.pg_roles)
    THEN
    
        CREATE ROLE "consult.defaut" WITH
            LOGIN  
            PASSWORD 'AccèsDonnéesPubliques' ;
          
        COMMENT ON ROLE "consult.defaut" IS 'Rôle de connexion générique pour la consultation des données publiques. Membre de g_consult.' ;
        
    END IF ;
    
    IF NOT quote_ident('consult.defaut')::regrole IN (
        SELECT pg_auth_members.member
            FROM pg_auth_members
            WHERE pg_auth_members.roleid::regrole::text = 'g_consult'
    )
    THEN
    
        -- "consult.defaut" est rendu membre de g_consult
        -- s'il ne l'était pas déjà.
        GRANT g_consult TO "consult.defaut" ;
        
    END IF ;

    IF NOT 'g_admin' IN (
        SELECT pg_auth_members.member::regrole::text 
            FROM pg_auth_members
            WHERE pg_auth_members.roleid = quote_ident('consult.defaut')::regrole
                AND pg_auth_members.admin_option
    )
    THEN
    
        -- g_admin est rendu membre de "consult.defaut" avec
        -- l'option ADMIN s'il ne l'est pas déjà.
        GRANT "consult.defaut" TO g_admin WITH ADMIN OPTION ;
        
    END IF ;


------ 1.2 - AJUSTEMENTS DIVERS SUR LES PRIVILEGES ------

    -- on retire à public la possibilité de créer des objets dans le schéma de même nom
    
    IF has_schema_privilege('public', 'public', 'CREATE')
    THEN
    
        REVOKE CREATE ON SCHEMA public FROM public ;
        
    END IF ;

END
$$ ;


-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


----------------------------------------
------ 2 - PREPARATION DES OBJETS ------
----------------------------------------
/* 2.1 - CREATION DES SCHEMAS
   2.2 - TABLE GESTION_SCHEMA
   2.3 - TABLE DE PARAMETRAGE
   2.4 - VUES D'ALIMENTATION DE GESTION_SCHEMA
   2.5 - VUE POUR MENUBUILDER
   2.6 - VUE POUR ASGARDMENU
   2.7 - VUE POUR ASGARDMANAGER
   2.8 - VERSION LECTURE SEULE DE GESTION_SCHEMA_USR */



------ 2.1 - CREATION DES SCHEMAS ------

-- Schema: z_asgard_admin

CREATE SCHEMA z_asgard_admin
    AUTHORIZATION g_admin ;
    
COMMENT ON SCHEMA z_asgard_admin IS 'ASGARD. Administration - RESERVE ADL.' ;

GRANT USAGE ON SCHEMA z_asgard_admin TO g_admin_ext ;


-- Schema: z_asgard

CREATE SCHEMA z_asgard
    AUTHORIZATION g_admin_ext ;
    
COMMENT ON SCHEMA z_asgard IS 'ASGARD. Utilitaires pour la gestion des droits.' ;

GRANT USAGE ON SCHEMA z_asgard TO public ;


------ 2.2 - TABLE GESTION_SCHEMA ------

-- Table: z_asgard_admin.gestion_schema

CREATE TABLE z_asgard_admin.gestion_schema
(
    bloc character varying(1) COLLATE pg_catalog."default",
    nomenclature boolean NOT NULL DEFAULT False,
    niv1 character varying COLLATE pg_catalog."default",
    niv1_abr character varying COLLATE pg_catalog."default",
    niv2 character varying COLLATE pg_catalog."default",
    niv2_abr character varying COLLATE pg_catalog."default",
    nom_schema character varying COLLATE pg_catalog."default" NOT NULL,
    oid_schema oid,
    creation boolean NOT NULL DEFAULT False,
    producteur character varying COLLATE pg_catalog."default" NOT NULL,
    oid_producteur oid,
    editeur character varying COLLATE pg_catalog."default",
    oid_editeur oid,
    lecteur character varying COLLATE pg_catalog."default", 
    oid_lecteur oid,
    ctrl text[],
    CONSTRAINT gestion_schema_pkey PRIMARY KEY (nom_schema),
    CONSTRAINT gestion_schema_oid_schema_unique UNIQUE (oid_schema),
    CONSTRAINT gestion_schema_bloc_check CHECK (bloc IS NULL OR bloc = 'd' OR nom_schema::text ~ (('^'::text || bloc::text) || '_'::text) AND bloc ~ '^[a-z]$'),
    CONSTRAINT gestion_schema_oid_roles_check CHECK ((oid_lecteur IS NULL OR NOT oid_lecteur = oid_producteur)
                                                    AND (oid_editeur IS NULL OR NOT oid_editeur = oid_producteur)
                                                    AND (oid_lecteur IS NULL OR oid_editeur IS NULL OR NOT oid_lecteur = oid_editeur)),
    CONSTRAINT gestion_schema_ctrl_check CHECK (ctrl IS NULL OR array_length(ctrl, 1) >= 2 AND ctrl[1] IN ('CREATE', 'RENAME', 'OWNER', 'DROP', 'SELF', 'MANUEL', 'EXIT', 'END')),
    CONSTRAINT gestion_schema_aucun_schema_systeme CHECK (
        NOT nom_schema IN ('public', 'information_schema', 'z_asgard_admin') 
        AND NOT nom_schema ~ '^pg_'
    )
)
WITH (
    OIDS = FALSE
)
TABLESPACE pg_default;

ALTER TABLE z_asgard_admin.gestion_schema
    OWNER to g_admin;

GRANT INSERT, SELECT, UPDATE, DELETE ON TABLE z_asgard_admin.gestion_schema TO g_admin_ext;

COMMENT ON TABLE z_asgard_admin.gestion_schema IS 'ASGARD. Table d''attribution des fonctions de producteur, éditeur et lecteur sur les schémas.' ;

COMMENT ON COLUMN z_asgard_admin.gestion_schema.bloc IS E'Le cas échéant, lettre identifiant le bloc normalisé auquel appartient le schéma, qui sera alors le préfixe du schéma :
c : schémas de consultation (mise à disposition de données publiques)
w : schémas de travail ou d''unité
s : géostandards
p : schémas thématiques ou dédiés à une application
r : référentiels
x : données confidentielles
e : données externes (opendata, etc.)
z : utilitaires.' ;
COMMENT ON COLUMN z_asgard_admin.gestion_schema.nomenclature IS 'Booléen. True si le schéma est répertorié dans la nomenclature COVADIS, False sinon.' ;
COMMENT ON COLUMN z_asgard_admin.gestion_schema.niv1 IS 'Nomenclature. Premier niveau d''arborescence (forme littérale).' ;
COMMENT ON COLUMN z_asgard_admin.gestion_schema.niv1_abr IS 'Nomenclature. Premier niveau d''arborescence (forme normalisée).' ;
COMMENT ON COLUMN z_asgard_admin.gestion_schema.niv2 IS 'Nomenclature. Second niveau d''arborescence (forme littérale).' ;
COMMENT ON COLUMN z_asgard_admin.gestion_schema.niv2_abr IS 'Nomenclature. Second niveau d''arborescence (forme normalisée).' ;
COMMENT ON COLUMN z_asgard_admin.gestion_schema.nom_schema IS 'Nom du schéma. Clé primaire.' ;
COMMENT ON COLUMN z_asgard_admin.gestion_schema.oid_schema IS 'Identifiant système du schéma.' ;
COMMENT ON COLUMN z_asgard_admin.gestion_schema.creation IS 'Booléen. True si le schéma existe dans le base de données, False sinon.' ;
COMMENT ON COLUMN z_asgard_admin.gestion_schema.producteur IS 'Rôle désigné comme producteur pour le schéma (modification des objets).' ;
COMMENT ON COLUMN z_asgard_admin.gestion_schema.oid_producteur IS 'Identifiant système du rôle producteur.' ;
COMMENT ON COLUMN z_asgard_admin.gestion_schema.editeur IS 'Rôle désigné comme éditeur pour le schéma (modification des données).' ;
COMMENT ON COLUMN z_asgard_admin.gestion_schema.oid_editeur IS 'Identifiant système du rôle éditeur.' ;
COMMENT ON COLUMN z_asgard_admin.gestion_schema.lecteur IS 'Rôle désigné comme lecteur pour le schéma (consultation des données).' ;
COMMENT ON COLUMN z_asgard_admin.gestion_schema.oid_lecteur IS 'Identitifiant système du rôle lecteur.' ;
COMMENT ON COLUMN z_asgard_admin.gestion_schema.ctrl IS 'Champ de contrôle.' ;

-- la table est marquée comme table de configuration de l'extension
SELECT pg_extension_config_dump('z_asgard_admin.gestion_schema'::regclass, '') ;


------- 2.3 - TABLE DE CONFIGURATION ------

-- Type: z_asgard_admin.asgard_parametre_type

CREATE TYPE z_asgard_admin.asgard_parametre_type AS ENUM (
	'autorise_producteur_connexion', 
    'autorise_producteur_membre_g_admin',
    'g_admin_sans_permission_producteurs', 
    'g_admin_sans_admin_option_producteurs',
    'createur_sans_admin_option_producteurs',
    'createur_avec_permission_editeurs_lecteurs',
    'createur_avec_admin_option_editeurs_lecteurs',
    'createur_avec_set_inherit_option_editeurs_lecteurs',
    'autorise_objets_inconnus',
    'sans_explicitation_set_inherit_option'
) ;

ALTER TYPE z_asgard_admin.asgard_parametre_type OWNER TO g_admin ;

COMMENT ON TYPE z_asgard_admin.asgard_parametre_type IS 'ASGARD. Paramètre de configuration.' ;

CREATE CAST (text AS z_asgard_admin.asgard_parametre_type)
    WITH INOUT
    AS IMPLICIT ;

-- Table: z_asgard_admin.asgard_configuration

CREATE TABLE z_asgard_admin.asgard_configuration (
    parametre z_asgard_admin.asgard_parametre_type PRIMARY KEY
) ;

ALTER TABLE z_asgard_admin.asgard_configuration OWNER TO g_admin ;

GRANT SELECT ON TABLE z_asgard_admin.asgard_configuration TO g_admin_ext ;

COMMENT ON TABLE z_asgard_admin.asgard_configuration IS 'ASGARD. Table de configuration.
Ajouter un paramètre permet d''obtenir l''effet correspondant, le supprimer de la table retire l''effet, de manière non rétro-active dans les deux cas.' ;

COMMENT ON COLUMN z_asgard_admin.asgard_configuration.parametre IS 'Nom du paramètre. 
Les valeurs autorisées sont les suivantes : 
- "autorise_producteur_connexion" > Autorise les rôles de connexion à être producteurs de schémas.
- "autorise_producteur_membre_g_admin" > Autorise les rôles membres de g_admin (y compris par héritage) à être producteurs de schémas, même s''il n''est pas possible de rendre g_admin membre de ces rôles. 
- "g_admin_sans_permission_producteurs" > Asgard ne tentera pas de rendre g_admin membre des rôles producteurs des schémas. Il n''est alors pas non plus vérifié si les producteurs sont membres de g_admin, même si le paramètre "autorise_producteur_membre_g_admin" n''est pas présent.
- "g_admin_sans_admin_option_producteurs" > Sauf à ce que "g_admin_sans_permission_producteurs" soit présent, Asgard continuera à rendre g_admin membre des rôles producteurs des schémas, mais sans lui donner l''option ADMIN.
- "autorise_objets_inconnus" > Evite l''émission d''erreurs lors de la manipulation d''objets rattachés à des schémas qui ne sont pas (encore) pris en charge par Asgard. Elles seront généralement remplacées par des avertissements de même teneur. Ce paramètre peut être pertinent pour permettre l''usage d''objets introduits par une nouvelle version de PostgreSQL avec laquelle Asgard n''a pas encore été mis en compatibilité.
- "createur_sans_admin_option_producteurs" > Pour les versions de PostgreSQL antérieures à 16 uniquement. Asgard continuera à rendre un rôle non super-utilisateur qui crée un rôle producteur via la table de gestion d''Asgard membre dudit rôle, mais sans l''option ADMIN.
- "createur_avec_permission_editeurs_lecteurs" > Pour les versions de PostgreSQL antérieures à 16 uniquement. Asgard rendra le rôle non super-utilisateur qui a créé un rôle éditeur ou lecteur via la table de gestion d''Asgard membre dudit rôle (sans l''option ADMIN).
- "createur_avec_admin_option_editeurs_lecteurs" > Pour les versions de PostgreSQL antérieures à 16 uniquement. Si "createur_avec_permission_editeurs_lecteurs" est également présent, Asgard rendra un rôle non super-utilisateur qui crée un rôle éditeur ou lecteur via la table de gestion d''Asgard membre dudit rôle avec l''option ADMIN.
- "createur_avec_set_inherit_option_editeurs_lecteurs" > Pour PostgreSQL 16 ou supérieur uniquement. Asgard conférera systématiquement les options SET et INHERIT au rôle non super-utilisateur qui vient de créer un rôle éditeur ou lecteur sur ce dernier, en plus de l''option ADMIN conférée automatiquement par PostgreSQL.
- "sans_explicitation_set_inherit_option" > Pour PostgreSQL 16 ou supérieur uniquement. Asgard ne s''autorisera plus à conférer les options SET et INHERIT à un rôle qui disposait déjà de l''option ADMIN sur un autre rôle.' ;

-- la table est marquée comme table de configuration de l'extension
SELECT pg_extension_config_dump('z_asgard_admin.asgard_configuration'::regclass, '') ;


------ 2.4 - VUES D'ALIMENTATION DE GESTION_SCHEMA ------

-- Function: z_asgard.asgard_has_role_usage(text, text)

CREATE OR REPLACE FUNCTION z_asgard.asgard_has_role_usage(
    role_parent text,
    role_enfant text DEFAULT current_user
    )
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
/* Détermine si un rôle est membre d'un autre (y compris indirectement) et hérite de ses droits. 

    Cette fonction est équivalente à pg_has_role(role_enfant, role_parent, 'USAGE')
    en plus permissif - elle renvoie False quand l'un des rôles
    n'existe pas plutôt que d'échouer.

    Parameters
    ----------
    role_parent : text
        Nom du rôle dont on souhaite savoir si l'autre est membre.
    role_enfant : text, optional
        Nom du rôle dont on souhaite savoir s'il est membre de l'autre.
        Si non renseigné, la fonction testera l'utilisateur courant.
    
    Returns
    -------
    boolean
        True si la relation entre les rôles est vérifiée. False
        si elle ne l'est pas ou si l'un des rôles n'existe pas.

*/
BEGIN
    
    RETURN pg_has_role(role_enfant, role_parent, 'USAGE') ;
    
EXCEPTION WHEN undefined_object
THEN
    RETURN False ;
    
END
$_$;

ALTER FUNCTION z_asgard.asgard_has_role_usage(text, text)
    OWNER TO g_admin_ext ;

COMMENT ON FUNCTION z_asgard.asgard_has_role_usage(text, text) IS 'ASGARD. Le second rôle est-il membre du premier (avec héritage de ses droits) ?' ;


-- View: z_asgard.gestion_schema_usr

CREATE OR REPLACE VIEW z_asgard.gestion_schema_usr AS (
    SELECT
        gestion_schema.nom_schema,
        gestion_schema.bloc,
        gestion_schema.nomenclature,
        gestion_schema.niv1,
        gestion_schema.niv1_abr,
        gestion_schema.niv2,
        gestion_schema.niv2_abr,
        gestion_schema.creation,
        gestion_schema.producteur,
        gestion_schema.editeur,
        gestion_schema.lecteur  
        FROM z_asgard_admin.gestion_schema
        WHERE pg_has_role('g_admin'::text, 'USAGE'::text) OR
            CASE
                WHEN gestion_schema.creation AND gestion_schema.oid_producteur IS NULL
                    THEN pg_has_role(gestion_schema.producteur::text, 'USAGE'::text)
                WHEN gestion_schema.creation
                    THEN pg_has_role(gestion_schema.oid_producteur, 'USAGE'::text)
                ELSE z_asgard.asgard_has_role_usage(gestion_schema.producteur)
            END
) ;

ALTER VIEW z_asgard.gestion_schema_usr
    OWNER TO g_admin_ext;
    
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE z_asgard.gestion_schema_usr TO public ;

COMMENT ON VIEW z_asgard.gestion_schema_usr IS 'ASGARD. Vue pour la gestion courante des schémas - création et administration des droits.' ;

COMMENT ON COLUMN z_asgard.gestion_schema_usr.bloc IS E'Le cas échéant, lettre identifiant le bloc normalisé auquel appartient le schéma, qui sera alors le préfixe du schéma :
c : schémas de consultation (mise à disposition de données publiques)
w : schémas de travail ou d''unité
s : géostandards
p : schémas thématiques ou dédiés à une application
r : référentiels
x : données confidentielles
e : données externes (opendata, etc.)
z : utilitaires.' ;
COMMENT ON COLUMN z_asgard.gestion_schema_usr.nomenclature IS 'Booléen. True si le schéma est répertorié dans la nomenclature COVADIS, False sinon.' ;
COMMENT ON COLUMN z_asgard.gestion_schema_usr.niv1 IS 'Nomenclature. Premier niveau d''arborescence (forme littérale).' ;
COMMENT ON COLUMN z_asgard.gestion_schema_usr.niv1_abr IS 'Nomenclature. Premier niveau d''arborescence (forme normalisée).' ;
COMMENT ON COLUMN z_asgard.gestion_schema_usr.niv2 IS 'Nomenclature. Second niveau d''arborescence (forme littérale).' ;
COMMENT ON COLUMN z_asgard.gestion_schema_usr.niv2_abr IS 'Nomenclature. Second niveau d''arborescence (forme normalisée).' ;
COMMENT ON COLUMN z_asgard.gestion_schema_usr.nom_schema IS 'Nom du schéma.' ;
COMMENT ON COLUMN z_asgard.gestion_schema_usr.creation IS 'Booléen. True si le schéma existe dans le base de données, False sinon.' ;
COMMENT ON COLUMN z_asgard.gestion_schema_usr.producteur IS 'Rôle désigné comme producteur pour le schéma (modification des objets).' ;
COMMENT ON COLUMN z_asgard.gestion_schema_usr.editeur IS 'Rôle désigné comme éditeur pour le schéma (modification des données).' ;
COMMENT ON COLUMN z_asgard.gestion_schema_usr.lecteur IS 'Rôle désigné comme lecteur pour le schéma (consultation des données).' ;


-- View: z_asgard.gestion_schema_etr

CREATE OR REPLACE VIEW z_asgard.gestion_schema_etr AS (
    SELECT
        gestion_schema.bloc,
        gestion_schema.nom_schema,
        gestion_schema.oid_schema,
        gestion_schema.creation,
        gestion_schema.producteur,
        gestion_schema.oid_producteur,
        gestion_schema.editeur,
        gestion_schema.oid_editeur,
        gestion_schema.lecteur,
        gestion_schema.oid_lecteur,
        gestion_schema.ctrl
        FROM z_asgard_admin.gestion_schema
        WHERE pg_has_role('g_admin'::text, 'USAGE'::text) OR
            CASE
                WHEN gestion_schema.creation AND gestion_schema.oid_producteur IS NULL
                    THEN pg_has_role(gestion_schema.producteur::text, 'USAGE'::text)
                WHEN gestion_schema.creation
                    THEN pg_has_role(gestion_schema.oid_producteur, 'USAGE'::text)
                ELSE z_asgard.asgard_has_role_usage(gestion_schema.producteur)
            END
) ;

ALTER VIEW z_asgard.gestion_schema_etr
    OWNER TO g_admin_ext;
    
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE z_asgard.gestion_schema_etr TO public ;

COMMENT ON VIEW z_asgard.gestion_schema_etr IS 'ASGARD. Vue technique pour l''alimentation de la table z_asgard_admin.gestion_schema par les déclencheurs.' ;

COMMENT ON COLUMN z_asgard.gestion_schema_etr.bloc IS E'Le cas échéant, lettre identifiant le bloc normalisé auquel appartient le schéma, qui sera alors le préfixe du schéma :
c : schémas de consultation (mise à disposition de données publiques)
w : schémas de travail ou d''unité
s : géostandards
p : schémas thématiques ou dédiés à une application
r : référentiels
x : données confidentielles
e : données externes (opendata, etc.)
z : utilitaires.' ;
COMMENT ON COLUMN z_asgard.gestion_schema_etr.nom_schema IS 'Nom du schéma.' ;
COMMENT ON COLUMN z_asgard.gestion_schema_etr.oid_schema IS 'Identifiant système du schéma.' ;
COMMENT ON COLUMN z_asgard.gestion_schema_etr.creation IS 'Booléen. True si le schéma existe dans le base de données, False sinon.' ;
COMMENT ON COLUMN z_asgard.gestion_schema_etr.producteur IS 'Rôle désigné comme producteur pour le schéma (modification des objets).' ;
COMMENT ON COLUMN z_asgard.gestion_schema_etr.oid_producteur IS 'Identifiant système du rôle producteur.' ;
COMMENT ON COLUMN z_asgard.gestion_schema_etr.editeur IS 'Rôle désigné comme éditeur pour le schéma (modification des données).' ;
COMMENT ON COLUMN z_asgard.gestion_schema_etr.oid_editeur IS 'Identifiant système du rôle éditeur.' ;
COMMENT ON COLUMN z_asgard.gestion_schema_etr.lecteur IS 'Rôle désigné comme lecteur pour le schéma (consultation des données).' ;
COMMENT ON COLUMN z_asgard.gestion_schema_etr.oid_lecteur IS 'Identitifiant système du rôle lecteur.' ;
COMMENT ON COLUMN z_asgard.gestion_schema_etr.ctrl IS 'Champ de contrôle.' ;



------ 2.5 - VUE POUR MENUBUILDER ------ [supprimé version 1.1.1]

-- View: z_asgard.qgis_menubuilder_metadata


------ 2.6 - VUE POUR ASGARDMENU ------

-- View: z_asgard.asgardmenu_metadata

CREATE OR REPLACE VIEW z_asgard.asgardmenu_metadata AS (
    SELECT
        row_number() OVER(ORDER BY nom_schema) AS id,
        gestion_schema.nom_schema,
        gestion_schema.bloc,
        gestion_schema.niv1,
        gestion_schema.niv2,
        CASE WHEN pg_has_role(gestion_schema.oid_producteur, 'USAGE') THEN 'producteur'
            WHEN pg_has_role(gestion_schema.oid_editeur, 'USAGE') THEN 'editeur'
            WHEN pg_has_role(gestion_schema.oid_lecteur, 'USAGE') THEN 'lecteur'
            ELSE 'autre' END AS permission
    FROM z_asgard_admin.gestion_schema
    WHERE gestion_schema.creation
) ;

ALTER VIEW z_asgard.asgardmenu_metadata
    OWNER TO g_admin_ext ;
    
GRANT SELECT ON TABLE z_asgard.asgardmenu_metadata TO public ;

COMMENT ON VIEW z_asgard.asgardmenu_metadata IS 'ASGARD. Données utiles à l''extension QGIS AsgardMenu.' ;
COMMENT ON COLUMN z_asgard.asgardmenu_metadata.id IS 'Identifiant entier unique.' ;
COMMENT ON COLUMN z_asgard.asgardmenu_metadata.bloc IS E'Le cas échéant, lettre identifiant le bloc normalisé auquel appartient le schéma, qui sera alors le préfixe du schéma :
c : schémas de consultation (mise à disposition de données publiques)
w : schémas de travail ou d''unité
s : géostandards
p : schémas thématiques ou dédiés à une application
r : référentiels
x : données confidentielles
e : données externes (opendata, etc.)
z : utilitaires
d : [spécial, hors nomenclature] corbeille.' ;
COMMENT ON COLUMN z_asgard.asgardmenu_metadata.niv1 IS 'Nomenclature. Premier niveau d''arborescence (forme littérale).' ;
COMMENT ON COLUMN z_asgard.asgardmenu_metadata.niv2 IS 'Nomenclature. Second niveau d''arborescence (forme littérale).' ;
COMMENT ON COLUMN z_asgard.asgardmenu_metadata.nom_schema IS 'Nom du schéma.' ;
COMMENT ON COLUMN z_asgard.asgardmenu_metadata.permission IS 'Profil de droits de l''utilisateur pour le schéma de la relation : ''producteur'', ''editeur'', ''lecteur'' ou ''autre''.' ;


------ 2.7 - VUE POUR ASGARDMANAGER ------

-- View: z_asgard.asgardmanager_metadata

CREATE OR REPLACE VIEW z_asgard.asgardmanager_metadata AS (
    SELECT
        row_number() OVER(ORDER BY nom_schema) AS id,
        gestion_schema.nom_schema,
        gestion_schema.oid_producteur,
        gestion_schema.oid_editeur,
        gestion_schema.oid_lecteur
    FROM z_asgard_admin.gestion_schema
    WHERE gestion_schema.creation
) ;

ALTER VIEW z_asgard.asgardmanager_metadata
    OWNER TO g_admin_ext ;
    
GRANT SELECT ON TABLE z_asgard.asgardmanager_metadata TO public ;

COMMENT ON VIEW z_asgard.asgardmanager_metadata IS 'ASGARD. Données utiles à l''extension QGIS AsgardManager.' ;
COMMENT ON COLUMN z_asgard.asgardmanager_metadata.id IS 'Identifiant entier unique.' ;
COMMENT ON COLUMN z_asgard.asgardmanager_metadata.nom_schema IS 'Nom du schéma.' ;
COMMENT ON COLUMN z_asgard.asgardmanager_metadata.oid_producteur IS 'Identifiant système du rôle producteur.' ;
COMMENT ON COLUMN z_asgard.asgardmanager_metadata.oid_editeur IS 'Identifiant système du rôle éditeur.' ;
COMMENT ON COLUMN z_asgard.asgardmanager_metadata.oid_lecteur IS 'Identitifiant système du rôle lecteur.' ;


------ 2.8 - VERSION LECTURE SEULE DE GESTION_SCHEMA_USR ------

-- View: z_asgard.gestion_schema_read_only

CREATE OR REPLACE VIEW z_asgard.gestion_schema_read_only AS (
    SELECT
        row_number() OVER(ORDER BY nom_schema) AS id,
        gestion_schema.nom_schema,
        gestion_schema.bloc,
        gestion_schema.nomenclature,
        gestion_schema.niv1,
        gestion_schema.niv1_abr,
        gestion_schema.niv2,
        gestion_schema.niv2_abr,
        gestion_schema.creation,
        gestion_schema.producteur,
        gestion_schema.editeur,
        gestion_schema.lecteur  
        FROM z_asgard_admin.gestion_schema
) ;

ALTER VIEW z_asgard.gestion_schema_read_only
    OWNER TO g_admin_ext;
    
GRANT SELECT ON TABLE z_asgard.gestion_schema_read_only TO public ;

COMMENT ON VIEW z_asgard.gestion_schema_read_only IS 'ASGARD. Vue de consultation des droits définis sur les schémas. Accessible à tous en lecture seule.' ;

COMMENT ON COLUMN z_asgard.gestion_schema_read_only.id IS 'Identifiant entier unique.' ;
COMMENT ON COLUMN z_asgard.gestion_schema_read_only.bloc IS E'Le cas échéant, lettre identifiant le bloc normalisé auquel appartient le schéma, qui sera alors le préfixe du schéma :
c : schémas de consultation (mise à disposition de données publiques)
w : schémas de travail ou d''unité
s : géostandards
p : schémas thématiques ou dédiés à une application
r : référentiels
x : données confidentielles
e : données externes (opendata, etc.)
z : utilitaires.' ;
COMMENT ON COLUMN z_asgard.gestion_schema_read_only.nomenclature IS 'Booléen. True si le schéma est répertorié dans la nomenclature COVADIS, False sinon.' ;
COMMENT ON COLUMN z_asgard.gestion_schema_read_only.niv1 IS 'Nomenclature. Premier niveau d''arborescence (forme littérale).' ;
COMMENT ON COLUMN z_asgard.gestion_schema_read_only.niv1_abr IS 'Nomenclature. Premier niveau d''arborescence (forme normalisée).' ;
COMMENT ON COLUMN z_asgard.gestion_schema_read_only.niv2 IS 'Nomenclature. Second niveau d''arborescence (forme littérale).' ;
COMMENT ON COLUMN z_asgard.gestion_schema_read_only.niv2_abr IS 'Nomenclature. Second niveau d''arborescence (forme normalisée).' ;
COMMENT ON COLUMN z_asgard.gestion_schema_read_only.nom_schema IS 'Nom du schéma.' ;
COMMENT ON COLUMN z_asgard.gestion_schema_read_only.creation IS 'Booléen. True si le schéma existe dans le base de données, False sinon.' ;
COMMENT ON COLUMN z_asgard.gestion_schema_read_only.producteur IS 'Rôle désigné comme producteur pour le schéma (modification des objets).' ;
COMMENT ON COLUMN z_asgard.gestion_schema_read_only.editeur IS 'Rôle désigné comme éditeur pour le schéma (modification des données).' ;
COMMENT ON COLUMN z_asgard.gestion_schema_read_only.lecteur IS 'Rôle désigné comme lecteur pour le schéma (consultation des données).' ;


-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


---------------------------------------
------ 3 - FONCTIONS UTILITAIRES ------
---------------------------------------
/* 3.0 - PETITS OUTILS
   3.1 - LISTES DES DROITS SUR LES OBJETS D'UN SCHEMA
   3.2 - LISTE DES DROITS SUR UN OBJET
   3.3 - MODIFICATION DU PROPRIETAIRE D'UN SCHEMA ET SON CONTENU
   3.4 - TRANSFORMATION GRANT EN REVOKE
   3.5 - INITIALISATION DE GESTION_SCHEMA
   3.6 - DEREFERENCEMENT D'UN SCHEMA
   3.7 - NETTOYAGE DE LA TABLE DE GESTION
   3.8 - REINITIALISATION DES PRIVILEGES SUR UN SCHEMA
   3.9 - REINITIALISATION DES PRIVILEGES SUR UN OBJET
   3.10 - DEPLACEMENT D'OBJET
   3.11 - OCTROI MASSIF DE PERMISSIONS SUR LES RÔLES
   3.12 - IMPORT DE LA NOMENCLATURE DANS GESTION_SCHEMA
   3.13 - REAFFECTATION DES PRIVILEGES D'UN RÔLE
   3.14 - REINITIALISATION DES PRIVILEGES SUR TOUS LES SCHEMAS
   4.15 - TRANSFORMATION D'UN NOM DE RÔLE POUR COMPARAISON AVEC LES CHAMPS ACL
   3.16 - DIAGNOSTIC DES DROITS NON STANDARDS
   3.17 - EXTRACTION DE NOMS D'OBJETS A PARTIR D'IDENTIFIANTS
   3.18 - EXPLICITATION DES CODES DE PRIVILÈGES
   3.19 - RECHERCHE DE LECTEURS ET EDITEURS
   3.20 - RECHERCHE DU MEILLEUR RÔLE POUR REALISER UNE OPERATION
   3.21 - CONSULTATION DE LA CONFIGURATION D'ASGARD
   3.22 - CREATION D'UN RÔLE
   3.23 - RECUPERATION D'INFORMATIONS DE LA TABLE DE GESTION */


------ 3.0 - PETITS OUTILS ------

-- NB : Entrent dans cette catégorie des fonctions triviales dont
-- le résultat ne dépend pas de l'état de la base (elles ont l'attribut
-- IMMUTABLE) et qui n'ont pas de gestion d'erreur.

-- Function: z_asgard.asgard_est_schema_systeme(text)

CREATE OR REPLACE FUNCTION z_asgard.asgard_est_schema_systeme(nom_schema text) 
    RETURNS boolean
    AS $_$
/* Indique si le schéma considéré est un "schéma système" au sens d'Asgard.

    Asgard a une vision extensive des schémas système, qui incluent les
    schémas techniques de PostgreSQL, mais aussi plus largement tous les
    schémas qui n'ont pas vocation à être référencés dans la table de 
    gestion d'Asgard.

    Parameters
    ----------
    nom_schema : text
        Nom du schéma.

    Returns
    -------
    boolean

    Notes
    -----
    La contrainte gestion_schema_aucun_schema_systeme sur la table
    "z_asgard_admin"."gestion_schema" vise les mêmes schémas et
    devra être mise en cohérence si la présente fonction est modifiée.

    Version notes
    -------------
    v1.5.0
        (C) Création.

*/
    SELECT 
        coalesce(
            $1 IN ('public', 'information_schema', 'z_asgard_admin') 
                OR $1 ~ '^pg_',
            False
        )
    $_$
    LANGUAGE SQL
    IMMUTABLE ;

ALTER FUNCTION z_asgard.asgard_est_schema_systeme(text) OWNER TO g_admin_ext ;

COMMENT ON FUNCTION z_asgard.asgard_est_schema_systeme(text) IS 'ASGARD. Indique si le schéma considéré est un "schéma système" au sens d''Asgard.' ;


-- Function: z_asgard.asgard_table_owner_privileges()

CREATE OR REPLACE FUNCTION z_asgard.asgard_table_owner_privileges()
    RETURNS text[]
    LANGUAGE plpgsql
    IMMUTABLE
    AS $_$
/* Renvoie la liste des privilèges implicites des propriétaires des tables et 
   relations assimilées.

    Les privilèges renvoyés varient selon la version de
    PostgreSQL.

    Returns
    -------
    text[]

    Version notes
    -------------
    v1.5.0
        (C) Création.

*/
DECLARE
    privileges text[] := ARRAY[
        'SELECT', 'INSERT', 'UPDATE', 'DELETE',
        'TRUNCATE', 'REFERENCES', 'TRIGGER'
    ] ;
BEGIN

    IF current_setting('server_version_num')::int < 170000
    THEN
        RETURN privileges ;
    ELSE 
        RETURN array_append(privileges, 'MAINTAIN') ;
    END IF ;

END
$_$ ;

ALTER FUNCTION z_asgard.asgard_table_owner_privileges() OWNER TO g_admin_ext ;

COMMENT ON FUNCTION z_asgard.asgard_table_owner_privileges() IS 'ASGARD. Renvoie la liste des privilèges implicites des propriétaires des tables et relations assimilées.' ;


-- Function: z_asgard.asgard_table_owner_privileges_codes()

CREATE OR REPLACE FUNCTION z_asgard.asgard_table_owner_privileges_codes()
    RETURNS text
    LANGUAGE plpgsql
    IMMUTABLE
    AS $_$
/* Renvoie les codes des privilèges implicites des propriétaires des tables et 
   relations assimilées.

    Les privilèges renvoyés varient selon la version de
    PostgreSQL.

    Returns
    -------
    text
        La concaténation des codes de privilèges.

    Version notes
    -------------
    v1.5.0
        (C) Création.

*/
BEGIN

    IF current_setting('server_version_num')::int < 170000
    THEN
        RETURN 'rawdDxt' ;
    ELSE 
        RETURN 'rawdDxtm' ;
    END IF ;

END
$_$ ;

ALTER FUNCTION z_asgard.asgard_table_owner_privileges_codes() OWNER TO g_admin_ext ;

COMMENT ON FUNCTION z_asgard.asgard_table_owner_privileges_codes() IS 'Renvoie les codes des privilèges implicites des propriétaires des tables et relations assimilées.' ;


-- Function: z_asgard.asgard_prefixe_erreur(text, text)

CREATE OR REPLACE FUNCTION z_asgard.asgard_prefixe_erreur(
    erreur text, 
    prefixe text
) 
    RETURNS text
    LANGUAGE plpgsql
    IMMUTABLE
    AS $_$
/* Ajoute si nécessaire le préfixe identifiant la fonction au message d'erreur.

    Le préfixe n'est ajouté que si l'erreur n'a pas été
    explicitement émise par la fonction, auquel cas le
    message devrait commencer par le préfixe, suivi d'un
    nombre et d'un point.

    Lorsqu'il est ajouté, le préfixe sera complété par le nombre 0, 
    qui distingue les erreurs capturées par la fonction des erreurs 
    qu'elle émet.

    Le message fourni par "erreur" n'est pas supposé être NULL ou
    une chaîne de caractères vides. Si tel était toutefois le cas,
    la fonction remplacerait le message absent par l'expression 
    "Erreur indéfinie."

    Parameters
    ----------
    erreur : text
        Le message d'erreur.
    prefixe : text
        Une combinaison de lettres majuscules identifiant la 
        fonction qui d'Asgard émet ou relaie le message.

    Returns
    -------
    text

    Example
    -------
    >>> SELECT z_asgard.asgard_prefixe_erreur('Grave erreur !', 'FRE') ;
    ... 'FRE0. Grave erreur !'
    >>> SELECT z_asgard.asgard_prefixe_erreur('FRE1. Grave erreur !', 'FRE') ;
    ... 'FRE1. Grave erreur !'

    Raises
    ------
    syntax_error
        FPE1. Quand le préfixe n'est pas constitué de lettres majuscules
        simples.

    Version notes
    -------------
    v1.5.0
        (C) Création.

*/
BEGIN
    IF NOT prefixe ~ '^[A-Z]{2,}$'
    THEN
        RAISE EXCEPTION 'FPE1. Préfixe invalide : "%".', prefixe
            USING ERRCODE = 'syntax_error',
                DETAIL = 'Un préfixe doit être constitué d''au moins deux lettres simples majuscules.' ;
    END IF ;

    IF erreur ~ format('^%s[0-9]+[.]', prefixe)
    THEN
        RETURN erreur ;
    END IF ;

    RETURN format(
        '%s0. %s', 
        prefixe, 
        coalesce(nullif(erreur, ''), 'Erreur indéfinie.')
    ) ;
    -- NB: on veille à ce que la fonction ne renvoie jamais
    -- NULL, ce qui ne serait pas une valeur valide pour MESSAGE.
END
$_$ ;

ALTER FUNCTION z_asgard.asgard_prefixe_erreur(text, text) OWNER TO g_admin_ext ;

COMMENT ON FUNCTION z_asgard.asgard_prefixe_erreur(text, text) IS 'ASGARD. Ajoute si nécessaire le préfixe identifiant la fonction au message d''erreur.' ;


------ 3.1 - LISTES DES DROITS SUR LES OBJETS D'UN SCHEMA ------

-- Function: z_asgard.asgard_synthese_role(regnamespace, regrole)

CREATE OR REPLACE FUNCTION z_asgard.asgard_synthese_role(
    n_schema regnamespace, 
    n_role regrole
)
    RETURNS TABLE(commande text)
    LANGUAGE plpgsql
    AS $_$
/* Renvoie une table contenant une liste de commandes GRANT et REVOKE 
   permettant de recréer les droits de "n_role" sur les objets du schéma 
   "n_schema" (et le schéma lui-même).

    Parameters
    ----------
    n_schema : regnamespace
        Un nom de schéma valide, casté en regnamespace.
    n_role : regrole 
        Un nom de rôle valide, casté en regrole.

    Returns
    -------
    table
        Une table avec un unique champ nommé "commande".

    Notes
    -----
    La fonction ne se préoccupe pas de l'attribut "GRANT OPTION" pour les
    privilèges révoqués des propriétaires des objets, parce que -
    même si le champ d'ACL a toutes les chances de ne pas le montrer -
    un rôle ne peut pas perdre le droit de conférer des privilèges sur 
    un objet qu'il possède.

    Version notes
    -------------
    v1.5.0
        (M) La fonction préserve désormais les attributs 
            "GRANT OPTION" qui permettent aux rôles de conférer à 
            d'autres un privilège qu'ils ont reçu.
        (m) Recours à asgard_table_owner_privileges plutôt qu'une liste en
            dur pour les privilèges attendus du producteur d'une
            table ou assimilé, pour prendre en compte l'introduction
            du privilège MAINTAIN par PostgreSQL 17.
        (m) Les messages d'erreur émis par la fonction sont 
            désormais marqués du préfixe FSS.
        (d) Enrichissement du descriptif.

*/
DECLARE
    e_mssg text ;
    e_detl text ;
    e_hint text ;
    e_schema text ;
    e_errcode text ;
BEGIN
    ------ SCHEMAS ------
    -- privilèges attribués (hors propriétaire) :
    RETURN QUERY
        SELECT
            format(
                'GRANT %s ON SCHEMA %s TO %%I%s', 
                privilege, 
                n_schema,
                CASE WHEN acl.grantable THEN ' WITH GRANT OPTION' ELSE '' END
            )
            FROM pg_catalog.pg_namespace,
                aclexplode(nspacl) AS acl (grantor, grantee, privilege, grantable)
            WHERE oid = n_schema
                AND nspacl IS NOT NULL
                AND n_role = grantee
                AND NOT n_role = nspowner ;
    -- privilèges révoqués du propriétaire :
    RETURN QUERY
        SELECT format('REVOKE %s ON SCHEMA %s FROM %%I', expected_privilege, n_schema)
            FROM pg_catalog.pg_namespace,
                unnest(ARRAY['USAGE', 'CREATE']) AS expected_privilege
            WHERE oid = n_schema
                AND nspacl IS NOT NULL
                AND NOT expected_privilege IN (
                    SELECT privilege
                        FROM aclexplode(nspacl) AS acl (grantor, grantee, privilege, grantable)
                        WHERE n_role = grantee
                    )
                AND n_role = nspowner ;
    ------ TABLES ------
    -- inclut les vues, vues matérialisées, tables étrangères et partitionnées
    -- privilèges attribués (hors propriétaire) :
    RETURN QUERY
        SELECT 
            format(
                'GRANT %s ON TABLE %s TO %%I%s', 
                privilege, 
                oid::regclass,
                CASE WHEN acl.grantable THEN ' WITH GRANT OPTION' ELSE '' END
            )
            FROM pg_catalog.pg_class,
                aclexplode(relacl) AS acl (grantor, grantee, privilege, grantable)
            WHERE relnamespace = n_schema
                AND relkind IN ('r', 'v', 'm', 'f', 'p')
                AND relacl IS NOT NULL
                AND n_role = grantee
                AND NOT n_role = relowner ;
    -- privilèges révoqués du propriétaire :
    RETURN QUERY
        SELECT format('REVOKE %s ON TABLE %s FROM %%I', expected_privilege, oid::regclass)
            FROM pg_catalog.pg_class,
                unnest(z_asgard.asgard_table_owner_privileges()) AS expected_privilege
            WHERE relnamespace = n_schema
                AND relkind IN ('r', 'v', 'm', 'f', 'p')
                AND relacl IS NOT NULL
                AND NOT expected_privilege IN (
                    SELECT privilege
                        FROM aclexplode(relacl) AS acl (grantor, grantee, privilege, grantable)
                        WHERE n_role = grantee
                    )
                AND n_role = relowner ;
    ------ SEQUENCES ------
    -- privilèges attribués (hors propriétaire) :
    RETURN QUERY
        SELECT
            format(
                'GRANT %s ON SEQUENCE %s TO %%I%s', 
                privilege, 
                oid::regclass,
                CASE WHEN acl.grantable THEN ' WITH GRANT OPTION' ELSE '' END
            )
            FROM pg_catalog.pg_class,
                aclexplode(relacl) AS acl (grantor, grantee, privilege, grantable)
            WHERE relnamespace = n_schema
                AND relkind = 'S'
                AND relacl IS NOT NULL
                AND n_role = grantee
                AND NOT n_role = relowner ;
    -- privilèges révoqués du propriétaire :
    RETURN QUERY
        SELECT format('REVOKE %s ON SEQUENCE %s FROM %%I', expected_privilege, oid::regclass)
            FROM pg_catalog.pg_class,
                unnest(ARRAY['SELECT', 'USAGE', 'UPDATE']) AS expected_privilege
            WHERE relnamespace = n_schema
                AND relkind = 'S'
                AND relacl IS NOT NULL
                AND NOT expected_privilege IN (
                    SELECT privilege
                        FROM aclexplode(relacl) AS acl (grantor, grantee, privilege, grantable)
                        WHERE n_role = grantee
                    )
                AND n_role = relowner ;
    ------ COLONNES ------
    -- privilèges attribués :
    RETURN QUERY
        SELECT
            format(
                'GRANT %s (%I) ON TABLE %s TO %%I%s', 
                privilege, 
                attname, 
                attrelid::regclass,
                CASE WHEN acl.grantable THEN ' WITH GRANT OPTION' ELSE '' END
            )
            FROM pg_catalog.pg_class JOIN pg_catalog.pg_attribute
                     ON pg_class.oid = pg_attribute.attrelid,
                aclexplode(attacl) AS acl (grantor, grantee, privilege, grantable)
            WHERE relnamespace = n_schema
                AND attacl IS NOT NULL
                AND n_role = grantee ;
    ------ ROUTINES ------
    -- ... sous la dénomination FUNCTION jusqu'à PG 10, puis en
    -- tant que ROUTINE à partir de PG 11, afin que les commandes
    -- fonctionnent également avec les procédures.
    -- privilèges attribués (hors propriétaire) :
    RETURN QUERY
        SELECT
            format(
                'GRANT %s ON %s %s TO %%I%s', 
                privilege, 
                CASE WHEN current_setting('server_version_num')::int < 110000
                    THEN 'FUNCTION' ELSE 'ROUTINE' END,
                oid::regprocedure,
                CASE WHEN acl.grantable THEN ' WITH GRANT OPTION' ELSE '' END
            )
            FROM pg_catalog.pg_proc,
                aclexplode(proacl) AS acl (grantor, grantee, privilege, grantable)
            WHERE pronamespace = n_schema
                AND proacl IS NOT NULL
                AND n_role = grantee
                AND NOT n_role = proowner ;
    -- privilèges révoqués du propriétaire :
    RETURN QUERY
        SELECT format('REVOKE %s ON %s %s FROM %%I', expected_privilege, 
                CASE WHEN current_setting('server_version_num')::int < 110000
                    THEN 'FUNCTION' ELSE 'ROUTINE' END,
                oid::regprocedure)
            FROM pg_catalog.pg_proc,
                unnest(ARRAY['EXECUTE']) AS expected_privilege
            WHERE pronamespace = n_schema
                AND proacl IS NOT NULL
                AND NOT expected_privilege IN (
                    SELECT privilege
                        FROM aclexplode(proacl) AS acl (grantor, grantee, privilege, grantable)
                        WHERE n_role = grantee
                    )
                AND n_role = proowner ;
    ------ TYPES ------
    -- inclut les domaines
    -- privilèges attribués (hors propriétaire) :
    RETURN QUERY
        SELECT
            format(
                'GRANT %s ON TYPE %s.%I TO %%I%s',
                privilege,
                n_schema,
                typname,
                CASE WHEN acl.grantable THEN ' WITH GRANT OPTION' ELSE '' END
            )
            FROM pg_catalog.pg_type,
                aclexplode(typacl) AS acl (grantor, grantee, privilege, grantable)
            WHERE typnamespace = n_schema
                AND typacl IS NOT NULL
                AND n_role = grantee
                AND NOT n_role = typowner ;
    -- privilèges révoqués du propriétaire :
    RETURN QUERY
        SELECT format('REVOKE %s ON TYPE %s.%I FROM %%I', expected_privilege, n_schema, typname)
            FROM pg_catalog.pg_type,
                unnest(ARRAY['USAGE']) AS expected_privilege
            WHERE typnamespace = n_schema
                AND typacl IS NOT NULL
                AND NOT expected_privilege IN (
                    SELECT privilege
                        FROM aclexplode(typacl) AS acl (grantor, grantee, privilege, grantable)
                        WHERE n_role = grantee
                    )
                AND n_role = typowner ;

EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                            e_hint = PG_EXCEPTION_HINT,
                            e_detl = PG_EXCEPTION_DETAIL,
                            e_errcode = RETURNED_SQLSTATE,
                            e_schema = SCHEMA_NAME ;
    
    RAISE EXCEPTION '%', z_asgard.asgard_prefixe_erreur(e_mssg, 'FSS')
        USING DETAIL = e_detl,
            HINT = e_hint,
            SCHEMA = e_schema,
            ERRCODE = e_errcode ;

END
$_$ ;

ALTER FUNCTION z_asgard.asgard_synthese_role(regnamespace, regrole)
    OWNER TO g_admin_ext ;

COMMENT ON FUNCTION z_asgard.asgard_synthese_role(regnamespace, regrole) IS 'ASGARD. Liste les commandes permettant de reproduire les droits d''un rôle sur les objets d''un schéma.' ;


-- Function: z_asgard.asgard_synthese_public(regnamespace)

CREATE OR REPLACE FUNCTION z_asgard.asgard_synthese_public(n_schema regnamespace)
    RETURNS TABLE(commande text)
    LANGUAGE plpgsql
    AS $_$
/* Renvoie une table contenant une liste de commandes GRANT et REVOKE permettant de
   recréer les droits de public sur les objets du schéma "schema" et le schéma lui-même.

    La fonction ne s'intéresse pas aux objets de type routine (fonctions, dont 
    agrégats, et procédures) et type (dont domaines), sur lesquels public reçoit 
    des droits par défaut qu'il n'est pas judicieux de reproduire sur un autre rôle, 
    ni de révoquer lors d'un changement de lecteur/éditeur. Si des privilèges
    par défaut ont été révoqués pour public, la révocation restera valable
    pour les futurs lecteur/éditeurs puisqu'il n'y a pas d'attribution de 
    privilèges supplémentaires pour les lecteurs/éditeurs sur ces objets.

    Parameters
    ----------
    n_schema : regnamespace
        Un nom de schéma valide, casté en regnamespace.

    Returns
    -------
    table
        Une table avec un unique champ nommé "commande".

    Notes
    -----
    Le pseudo-rôle "public" ne peut pas recevoir des privilèges avec
    "GRANT OPTION", il est donc normal que la fonction ne s'en préoccupe
    pas.

    Version notes
    -------------
    v1.5.0
        (m) Les messages d'erreur émis par la fonction sont 
            désormais marqués du préfixe FSSP.
        (d) Amélioration formelle du descriptif.
        
*/
DECLARE
    e_mssg text ;
    e_detl text ;
    e_hint text ;
    e_schema text ;
    e_errcode text ;
BEGIN
    ------ SCHEMAS ------
    RETURN QUERY
        SELECT format('GRANT %s ON SCHEMA %s TO %%I', privilege, n_schema)
            FROM pg_catalog.pg_namespace,
                aclexplode(nspacl) AS acl (grantor, grantee, privilege, grantable)
            WHERE oid = n_schema
                AND nspacl IS NOT NULL
                AND grantee = 0 ;
    ------ TABLES ------
    -- inclut les vues, vues matérialisées, tables étrangères et partitions
    RETURN QUERY
        SELECT format('GRANT %s ON TABLE %s TO %%I', privilege, oid::regclass)
            FROM pg_catalog.pg_class,
                aclexplode(relacl) AS acl (grantor, grantee, privilege, grantable)
            WHERE relnamespace = n_schema
                AND relkind IN ('r', 'v', 'm', 'f', 'p')
                AND relacl IS NOT NULL
                AND grantee = 0 ;
    ------ SEQUENCES ------
    RETURN QUERY
        SELECT format('GRANT %s ON SEQUENCE %s TO %%I', privilege, oid::regclass)
            FROM pg_catalog.pg_class,
                aclexplode(relacl) AS acl (grantor, grantee, privilege, grantable)
            WHERE relnamespace = n_schema
                AND relkind = 'S'
                AND relacl IS NOT NULL
                AND grantee = 0 ;
    ------ COLONNES ------
    RETURN QUERY
        SELECT format('GRANT %s (%I) ON TABLE %s TO %%I', privilege, attname, attrelid::regclass)
            FROM pg_catalog.pg_class JOIN pg_catalog.pg_attribute
                     ON pg_class.oid = pg_attribute.attrelid,
                aclexplode(attacl) AS acl (grantor, grantee, privilege, grantable)
            WHERE relnamespace = n_schema
                AND attacl IS NOT NULL
                AND grantee = 0 ;

EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                            e_hint = PG_EXCEPTION_HINT,
                            e_detl = PG_EXCEPTION_DETAIL,
                            e_errcode = RETURNED_SQLSTATE,
                            e_schema = SCHEMA_NAME ;
    
    RAISE EXCEPTION '%', z_asgard.asgard_prefixe_erreur(e_mssg, 'FSSP')
        USING DETAIL = e_detl,
            HINT = e_hint,
            SCHEMA = e_schema,
            ERRCODE = e_errcode ;

END
$_$ ;

ALTER FUNCTION z_asgard.asgard_synthese_public(regnamespace)
    OWNER TO g_admin_ext ;

COMMENT ON FUNCTION z_asgard.asgard_synthese_public(regnamespace) IS 'ASGARD. Liste les commandes permettant de reproduire les droits de public sur les objets d''un schéma.' ;


------ 3.2 - LISTE DES DROITS SUR UN OBJET ------

-- Function: z_asgard.asgard_synthese_role_obj(oid, text, regrole)

CREATE OR REPLACE FUNCTION z_asgard.asgard_synthese_role_obj(
    obj_oid oid, 
    obj_type text, 
    n_role regrole
)
    RETURNS TABLE(commande text)
    LANGUAGE plpgsql
    AS $_$
/* Renvoie une table contenant une liste de commandes GRANT et REVOKE 
   permettant de recréer les droits de "n_role" sur un objet de type
   table, table étrangère, partition de table, vue, vue matérialisée, 
   séquence, routine (fonctions, dont agrégats, et procédures), type 
   (dont domaines).

    Parameters
    ----------
    obj_oid : oid
        L'identifiant interne de l'objet.
    obj_type : {
        'table', 'view', 'materialized view', 'sequence', 
        'function', 'type', 'domain', 'foreign table', 
        'partitioned table', 'aggregate','procedure', 'routine'
    }
        Le type de l'objet considéré.
    n_role : regrole
        Un nom de rôle valide, casté en regrole.

    Returns
    -------
    table
        Une table avec un unique champ nommé "commande".

    Raises
    ------
    invalid_parameter_value
        FSO1. Si la valeur du paramètre "obj_type" n'est pas reconnue.
        Ajouter le paramètre 'autorise_objets_inconnus' à la table de
        configuration d'Asgard permet d'émettre un avertissement plutôt
        qu'une erreur.

    Notes
    -----
    La fonction ne se préoccupe pas de l'attribut "GRANT OPTION" pour les
    privilèges révoqués des propriétaires des objets, parce que -
    même si le champ d'ACL a toutes les chances de ne pas le montrer -
    un rôle ne peut pas perdre le droit de conférer des privilèges sur 
    un objet qu'il possède.

    Version notes
    -------------
    v1.5.0
        (M) La fonction est préserve désormais les attributs 
            "GRANT OPTION" qui permettent aux rôles de conférer à 
            d'autres un privilège qu'ils ont reçu.
        (m) Recours à asgard_table_owner_privileges plutôt qu'une liste en
            dur pour les privilèges attendus du producteur d'une
            table ou assimilé, pour prendre en compte l'introduction
            du privilège MAINTAIN par PostgreSQL 17.
        (m) Les messages d'erreur émis par la fonction sont 
            désormais marqués du préfixe FSO.
        (m) Le paramètre de configuration 'autorise_objets_inconnus' permet 
            désormais l'émission d'un avertissement au lieu d'une erreur 
            lorsque la valeur de "obj_type" n'est pas reconnue. Le code
            de cette erreur, anciennement FSR0, devient FSO1.
        (d) Amélioration formelle du descriptif.

*/
DECLARE
    e_mssg text ;
    e_detl text ;
    e_hint text ;
    e_schema text ;
    e_errcode text ;
BEGIN       
    ------ TABLE, VUE, VUE MATERIALISEE ------
    IF obj_type IN ('table', 'view', 'materialized view', 'foreign table', 'partitioned table')
    THEN
        -- privilèges attribués (si n_role n'est pas le propriétaire de l'objet) :
        RETURN QUERY
            SELECT
                format(
                    'GRANT %s ON TABLE %s TO %%I%s', 
                    privilege, 
                    oid::regclass,
                    CASE WHEN acl.grantable THEN ' WITH GRANT OPTION' ELSE '' END
                )
                FROM pg_catalog.pg_class,
                    aclexplode(relacl) AS acl (grantor, grantee, privilege, grantable)
                WHERE oid = obj_oid
                    AND relacl IS NOT NULL
                    AND n_role = grantee
                    AND NOT n_role = relowner ;
        -- privilèges révoqués du propriétaire (si n_role est le propriétaire de l'objet) :
        RETURN QUERY
            SELECT format('REVOKE %s ON TABLE %s FROM %%I', expected_privilege, oid::regclass)
                FROM pg_catalog.pg_class,
                    unnest(z_asgard.asgard_table_owner_privileges()) AS expected_privilege
                WHERE oid = obj_oid
                    AND relacl IS NOT NULL
                    AND NOT expected_privilege IN (
                        SELECT privilege
                            FROM aclexplode(relacl) AS acl (grantor, grantee, privilege, grantable)
                            WHERE n_role = grantee
                        )
                    AND n_role = relowner ;
        ------ COLONNES ------
        -- privilèges attribués :
        RETURN QUERY
            SELECT
                format(
                    'GRANT %s (%I) ON TABLE %s TO %%I%s', 
                    privilege, 
                    attname, 
                    attrelid::regclass,
                    CASE WHEN acl.grantable THEN ' WITH GRANT OPTION' ELSE '' END
                )
                FROM pg_catalog.pg_attribute,
                    aclexplode(attacl) AS acl (grantor, grantee, privilege, grantable)
                WHERE pg_attribute.attrelid = obj_oid
                    AND attacl IS NOT NULL
                    AND n_role = grantee ;
    ------ SEQUENCES ------
    ELSIF obj_type = 'sequence'
    THEN
        -- privilèges attribués (si n_role n'est pas le propriétaire de l'objet) :
        RETURN QUERY
            SELECT
                format(
                    'GRANT %s ON SEQUENCE %s TO %%I%s', 
                    privilege, 
                    oid::regclass,
                    CASE WHEN acl.grantable THEN ' WITH GRANT OPTION' ELSE '' END
                )
                FROM pg_catalog.pg_class,
                    aclexplode(relacl) AS acl (grantor, grantee, privilege, grantable)
                WHERE oid = obj_oid
                    AND relacl IS NOT NULL
                    AND n_role = grantee
                    AND NOT n_role = relowner ;
        -- privilèges révoqués du propriétaire (si n_role est le propriétaire de l'objet) :
        RETURN QUERY
            SELECT format('REVOKE %s ON SEQUENCE %s FROM %%I', expected_privilege, oid::regclass)
                FROM pg_catalog.pg_class,
                    unnest(ARRAY['SELECT', 'USAGE', 'UPDATE']) AS expected_privilege
                WHERE oid = obj_oid
                    AND relacl IS NOT NULL
                    AND NOT expected_privilege IN (
                        SELECT privilege
                            FROM aclexplode(relacl) AS acl (grantor, grantee, privilege, grantable)
                            WHERE n_role = grantee
                        )
                    AND n_role = relowner ;
    ------ FONCTIONS ------
    -- ... sous la dénomination FUNCTION jusqu'à PG 10, puis en
    -- tant que ROUTINE à partir de PG 11, afin que les commandes
    -- fonctionnent également avec les procédures.
    ELSIF obj_type IN ('function', 'aggregate', 'procedure', 'routine')
    THEN
        -- privilèges attribués (si n_role n'est pas le propriétaire de l'objet) :
        RETURN QUERY
            SELECT
                format(
                    'GRANT %s ON %s %s TO %%I%s', 
                    privilege, 
                    CASE WHEN current_setting('server_version_num')::int < 110000
                        THEN 'FUNCTION' ELSE 'ROUTINE' END,
                    oid::regprocedure,
                    CASE WHEN acl.grantable THEN ' WITH GRANT OPTION' ELSE '' END
                )
                FROM pg_catalog.pg_proc,
                    aclexplode(proacl) AS acl (grantor, grantee, privilege, grantable)
                WHERE oid = obj_oid
                    AND proacl IS NOT NULL
                    AND n_role = grantee
                    AND NOT n_role = proowner ;
        -- privilèges révoqués du propriétaire (si n_role est le propriétaire de l'objet) :
        RETURN QUERY
            SELECT format('REVOKE %s ON %s %s FROM %%I', expected_privilege,
                    CASE WHEN current_setting('server_version_num')::int < 110000
                        THEN 'FUNCTION' ELSE 'ROUTINE' END,
                    oid::regprocedure)
                FROM pg_catalog.pg_proc,
                    unnest(ARRAY['EXECUTE']) AS expected_privilege
                WHERE oid = obj_oid
                    AND proacl IS NOT NULL
                    AND NOT expected_privilege IN (
                        SELECT privilege
                            FROM aclexplode(proacl) AS acl (grantor, grantee, privilege, grantable)
                            WHERE n_role = grantee
                        )
                    AND n_role = proowner ;
    ------ TYPES ------
    -- inclut les domaines
    ELSIF obj_type IN ('type', 'domain')
    THEN
        -- privilèges attribués (si n_role n'est pas le propriétaire de l'objet) :
        RETURN QUERY
            SELECT
                format(
                    'GRANT %s ON TYPE %s.%I TO %%I%s', 
                    privilege, 
                    typnamespace::regnamespace, 
                    typname,
                    CASE WHEN acl.grantable THEN ' WITH GRANT OPTION' ELSE '' END
                )
                FROM pg_catalog.pg_type,
                    aclexplode(typacl) AS acl (grantor, grantee, privilege, grantable)
                WHERE oid = obj_oid
                    AND typacl IS NOT NULL
                    AND n_role = grantee
                    AND NOT n_role = typowner ;
        -- privilèges révoqués du propriétaire (si n_role est le propriétaire de l'objet) :
        RETURN QUERY
            SELECT format('REVOKE %s ON TYPE %s.%I FROM %%I', expected_privilege, typnamespace::regnamespace, typname)
                FROM pg_catalog.pg_type,
                    unnest(ARRAY['USAGE']) AS expected_privilege
                WHERE oid = obj_oid
                    AND typacl IS NOT NULL
                    AND NOT expected_privilege IN (
                        SELECT privilege
                            FROM aclexplode(typacl) AS acl (grantor, grantee, privilege, grantable)
                            WHERE n_role = grantee
                        )
                    AND n_role = typowner ;
    ELSIF NOT z_asgard.asgard_parametre('autorise_objets_inconnus')
    THEN
       RAISE EXCEPTION 'FSO1. Le type d''objet % n''est pas pris en charge.', obj_type
           USING ERRCODE = 'invalid_parameter_value' ;
    ELSE
        RAISE WARNING 'FSO1. Le type d''objet % n''est pas pris en charge. Les privilèges ne seront pas modifiés.', obj_type ;
    END IF ;

EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                            e_hint = PG_EXCEPTION_HINT,
                            e_detl = PG_EXCEPTION_DETAIL,
                            e_errcode = RETURNED_SQLSTATE,
                            e_schema = SCHEMA_NAME ;
    
    RAISE EXCEPTION '%', z_asgard.asgard_prefixe_erreur(e_mssg, 'FSO')
        USING DETAIL = e_detl,
            HINT = e_hint,
            SCHEMA = e_schema,
            ERRCODE = e_errcode ;

END
$_$ ;

ALTER FUNCTION z_asgard.asgard_synthese_role_obj(oid, text, regrole)
    OWNER TO g_admin_ext ;

COMMENT ON FUNCTION z_asgard.asgard_synthese_role_obj(oid, text, regrole) IS 'ASGARD. Liste les commandes permettant de reproduire les droits d''un rôle sur un objet.' ;


-- Function: z_asgard.asgard_synthese_public_obj(oid, text)

CREATE OR REPLACE FUNCTION z_asgard.asgard_synthese_public_obj(obj_oid oid, obj_type text)
    RETURNS TABLE(commande text)
    LANGUAGE plpgsql
    AS $_$
/* Renvoie une table contenant une liste de commandes GRANT et REVOKE 
   permettant de recréer les droits de public sur un objet de type
   table, table étrangère, partition de table, vue, vue matérialisée 
   ou séquence.

    La fonction ne s'intéresse pas aux objets de type routine (fonctions, dont 
    agrégats, et procédures) et type (dont domaines), sur lesquels public reçoit 
    des droits par défaut qu'il n'est pas judicieux de reproduire sur un autre rôle, 
    ni de révoquer lors d'un changement de lecteur/éditeur. Si des privilèges
    par défaut ont été révoqués pour public, la révocation restera valable
    pour les futurs lecteur/éditeurs puisqu'il n'y a pas d'attribution de 
    privilèges supplémentaires pour les lecteurs/éditeurs sur ces objets.

    Parameters
    ----------
    obj_oid : oid
        L'identifiant interne de l'objet.
    obj_type : {
        'table', 'view', 'materialized view', 'sequence', 
        'foreign table', 'partitioned table'
    }
        Le type de l'objet considéré.

    Returns
    -------
    table
        Une table avec un unique champ nommé "commande".

    Raises
    ------
    invalid_parameter_value
        FSOP1. Si la valeur du paramètre "obj_type" n'est pas reconnue.
        Ajouter le paramètre 'autorise_objets_inconnus' à la table de
        configuration d'Asgard permet d'émettre un avertissement plutôt
        qu'une erreur.

    Notes
    -----
    Le pseudo-rôle "public" ne peut pas recevoir des privilèges avec
    "GRANT OPTION", il est donc normal que la fonction ne s'en préoccupe
    pas.

    Version notes
    -------------
    v1.5.0
        (m) Les messages d'erreur émis par la fonction sont 
            désormais marqués du préfixe FSOP.
        (m) Le paramètre de configuration 'autorise_objets_inconnus' permet 
            désormais l'émission d'un avertissement au lieu d'une erreur 
            lorsque la valeur de "obj_type" n'est pas reconnue. Le code
            de cette erreur, anciennement FSP0, devient FSOP1.
        (d) Amélioration formelle du descriptif.

*/
DECLARE
    e_mssg text ;
    e_detl text ;
    e_hint text ;
    e_schema text ;
    e_errcode text ;
BEGIN
    ------ TABLE, VUE, VUE MATERIALISEE ------
    IF obj_type IN ('table', 'view', 'materialized view', 'foreign table', 'partitioned table')
    THEN
        RETURN QUERY
            SELECT format('GRANT %s ON TABLE %s TO %%I', privilege, oid::regclass)
                FROM pg_catalog.pg_class,
                    aclexplode(relacl) AS acl (grantor, grantee, privilege, grantable)
                WHERE oid = obj_oid
                    AND relacl IS NOT NULL
                    AND grantee = 0 ;
        ------ COLONNES ------
        RETURN QUERY
            SELECT format('GRANT %s (%I) ON TABLE %s TO %%I', privilege, attname, attrelid::regclass)
                FROM pg_catalog.pg_attribute,
                    aclexplode(attacl) AS acl (grantor, grantee, privilege, grantable)
                WHERE pg_attribute.attrelid = obj_oid
                    AND attacl IS NOT NULL
                    AND grantee = 0 ;
    ------ SEQUENCES ------
    ELSIF obj_type = 'sequence'
    THEN
        RETURN QUERY
            SELECT format('GRANT %s ON SEQUENCE %s TO %%I', privilege, oid::regclass)
                FROM pg_catalog.pg_class,
                    aclexplode(relacl) AS acl (grantor, grantee, privilege, grantable)
                WHERE oid = obj_oid
                    AND relacl IS NOT NULL
                    AND grantee = 0 ;
    ELSIF NOT z_asgard.asgard_parametre('autorise_objets_inconnus')
    THEN
       RAISE EXCEPTION 'FSOP1. Le type d''objet % n''est pas pris en charge.', obj_type
           USING ERRCODE = 'invalid_parameter_value' ;
    ELSE
        RAISE WARNING 'FSOP1. Le type d''objet % n''est pas pris en charge. Les privilèges ne seront pas modifiés.', obj_type ;
    END IF ;

EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                            e_hint = PG_EXCEPTION_HINT,
                            e_detl = PG_EXCEPTION_DETAIL,
                            e_errcode = RETURNED_SQLSTATE,
                            e_schema = SCHEMA_NAME ;
    
    RAISE EXCEPTION '%', z_asgard.asgard_prefixe_erreur(e_mssg, 'FSOP')
        USING DETAIL = e_detl,
            HINT = e_hint,
            SCHEMA = e_schema,
            ERRCODE = e_errcode ;

END
$_$ ;

ALTER FUNCTION z_asgard.asgard_synthese_public_obj(oid, text)
    OWNER TO g_admin_ext ;

COMMENT ON FUNCTION z_asgard.asgard_synthese_public_obj(oid, text) IS 'ASGARD. Fonction qui liste les commandes permettant de reproduire les droits de public sur un objet.' ;


------ 3.3 - MODIFICATION DU PROPRIETAIRE D'UN SCHEMA ET SON CONTENU ------

-- Function: z_asgard.asgard_admin_proprietaire(text, text, boolean)

CREATE OR REPLACE FUNCTION z_asgard.asgard_admin_proprietaire(
    n_schema text, n_owner text, b_setschema boolean DEFAULT True
    )
    RETURNS int
    LANGUAGE plpgsql
    AS $_$
/* Attribue un schéma et tous les objets qu'il contient au propriétaire désigné.

    Elle n'intervient que sur les objets qui n'appartiennent pas déjà au
    rôle considéré.

    Si l'utilisateur ne dispose pas des droits nécessaires pour réaliser
    certaines réaffectations d'objets, la fonction relaiera l'erreur
    générée par la fonction z_asgard.asgard_cherche_executant, sur
    laquelle elle s'appuie pour choisir le rôle qui exécute les commandes.

    Parameters
    ----------
    n_schema : text
        Chaîne de caractères correspondant au nom du schéma à considérer.
    n_owner : text
        Chaîne de caractères correspondant au nom du rôle qui doit être
        propriétaire des objets.
    b_setschema : boolean, default True
        Booléen qui indique si la fonction doit changer le propriétaire
        du schéma ou seulement des objets qu'il contient.

    Returns
    -------
    int
        Nombre d'objets effectivement traités. Les commandes lancées sont
        notifiées au fur et à mesure.

    Raises
    ------
    invalid_parameter_value
        FAP1. S'il n'existe pas de schéma portant le nom spécifié par "n_schema".
        FAP2. S'il n'existe pas de rôle portant le nom spécifié par "n_owner".
    raise_exception
        FAP3. Si le rôle spécifié par "n_owner" n'est pas le propriétaire du
        schéma "n_schema" et que "b_setschema" n'autorise pas la modification
        du propriétaire.

    Version notes
    -------------
    v1.5.0
        (M) Recours à asgard_cherche_executant pour trouver des 
            rôles habilités, le cas échéant, à modifier les 
            propriétaires des objets. Le contrôle des permissions
            de l'utilisateur est dorénavant entièrement délégué à 
            cette fonction.
        (m) Amélioration de la gestion des messages d'erreur.
        (d) Enrichissement du descriptif.

*/
DECLARE
    item record ;
    k int := 0 ;
    o_owner oid ;
    s_owner text ;
    e_mssg text ;
    e_hint text ;
    e_detl text ;
    e_errcode text ;
    e_schema text ;
    executant text ;
    utilisateur text := current_user ;
BEGIN
    ------ TESTS PREALABLES ------
    SELECT pg_roles.rolname
        INTO s_owner
        FROM pg_catalog.pg_namespace
            INNER JOIN pg_catalog.pg_roles ON pg_roles.oid = nspowner
        WHERE nspname = n_schema ;
    
    -- non existance du schémas
    IF NOT FOUND
    THEN
        RAISE EXCEPTION 'FAP1. Le schéma % n''existe pas.', n_schema
            USING ERRCODE = 'invalid_parameter_value' ;
    END IF ;
    
    -- le propriétaire désigné n'existe pas
    IF NOT n_owner IN (SELECT rolname FROM pg_catalog.pg_roles)
    THEN
        RAISE EXCEPTION 'FAP2. Le rôle % n''existe pas.', n_owner 
            USING ERRCODE = 'invalid_parameter_value' ; 
    ELSE
        o_owner := quote_ident(n_owner)::regrole::oid ;
    END IF ;
    
    -- le propriétaire désigné n'est pas le propriétaire courant et la fonction
    -- a été lancée avec la variante qui ne traite pas le schéma
    IF NOT b_setschema AND NOT n_owner = s_owner
    THEN
        RAISE EXCEPTION 'FAP3. Le rôle % n''est pas propriétaire du schéma.', n_owner
            USING HINT = format(
                'Lancez asgard_admin_proprietaire(%L, %L) pour changer également le propriétaire du schéma.',
                n_schema, n_owner
            ),
                ERRCODE = 'raise_exception' ;
    END IF ;
    
    ------ PROPRIÉTAIRE DU SCHEMA ------
    IF b_setschema AND NOT n_owner = s_owner
    THEN
        -- choix d'un rôle habilité à exécuter les commandes (sinon
        -- asgard_cherche_executant émet une erreur)
        executant := z_asgard.asgard_cherche_executant(
            'ALTER SCHEMA OWNER', 
            new_producteur := n_owner, 
            old_producteur := s_owner
        ) ;
        EXECUTE format('SET ROLE %I', executant) ;
        EXECUTE format('ALTER SCHEMA %I OWNER TO %I', n_schema, n_owner) ;
        RAISE NOTICE '> %', format('ALTER SCHEMA %I OWNER TO %I', n_schema, n_owner) ;
        k := k + 1 ;
        EXECUTE format('SET ROLE %I', utilisateur) ;
    END IF ;
    
    ------ PROPRIETAIRES DES OBJETS ------
    -- uniquement ceux qui n'appartiennent pas déjà
    -- au rôle identifié
    FOR item IN
        -- tables, tables étrangères, vues, vues matérialisées,
        -- partitions, séquences :
        SELECT
            relname::text AS n_objet,
            pg_roles.rolname AS obj_owner,
            relkind IN ('r', 'f', 'p', 'm') AS b,
            -- b servira à assurer que les tables soient listées avant les
            -- objets qui en dépendent
            format('ALTER %s %s OWNER TO %I',
                kind_lg, pg_class.oid::regclass, n_owner) AS commande
            FROM unnest(ARRAY['r', 'p', 'v', 'm', 'f', 'S'],
                       ARRAY['TABLE', 'TABLE', 'VIEW', 'MATERIALIZED VIEW', 'FOREIGN TABLE', 'SEQUENCE']) AS l (kind_crt, kind_lg),
                pg_catalog.pg_class
                INNER JOIN pg_catalog.pg_roles ON pg_roles.oid = relowner
            WHERE relnamespace = quote_ident(n_schema)::regnamespace
                AND relkind IN ('S', 'r', 'p', 'v', 'm', 'f')
                AND kind_crt = relkind
                AND NOT relowner = o_owner
        UNION
        -- fonctions et procédures :
        -- ... sous la dénomination FUNCTION jusqu'à PG 10, puis en
        -- tant que ROUTINE à partir de PG 11, afin que les commandes
        -- fonctionnent également avec les procédures.
        SELECT
            proname::text AS n_objet,
            pg_roles.rolname AS obj_owner,
            False AS b,
            format('ALTER %s %s OWNER TO %I',
                CASE WHEN current_setting('server_version_num')::int < 110000
                    THEN 'FUNCTION' ELSE 'ROUTINE' END,
                pg_proc.oid::regprocedure, n_owner) AS commande
            FROM pg_catalog.pg_proc
                INNER JOIN pg_catalog.pg_roles ON pg_roles.oid = proowner
            WHERE pronamespace = quote_ident(n_schema)::regnamespace
                AND NOT proowner = o_owner
            -- à noter que les agrégats (proisagg vaut True) ont
            -- leur propre commande ALTER AGGREGATE OWNER TO, mais
            -- ALTER FUNCTION OWNER TO fonctionne pour tous les types
            -- de fonctions dont les agrégats, et - pour PG 11+ - 
            -- ALTER ROUTINE OWNER TO fonctionne pour tous les types
            -- de fonctions et les procédures.
        UNION
        -- types et domaines :
        SELECT
            typname::text AS n_objet,
            pg_roles.rolname AS obj_owner,
            False AS b,
            format('ALTER %s %I.%I OWNER TO %I',
                kind_lg, n_schema, typname, n_owner) AS commande
            FROM unnest(ARRAY['true', 'false'],
                       ARRAY['DOMAIN', 'TYPE']) AS l (kind_crt, kind_lg),
                pg_catalog.pg_type
                INNER JOIN pg_catalog.pg_roles ON pg_roles.oid = typowner
            WHERE typnamespace = quote_ident(n_schema)::regnamespace
                AND kind_crt::boolean = (typtype = 'd')
                AND NOT typowner = o_owner
                -- exclusion des types générés automatiquement
                AND NOT (pg_type.oid, 'pg_type'::regclass::oid) IN (
                        SELECT pg_depend.objid, pg_depend.classid
                            FROM pg_catalog.pg_depend
                            WHERE deptype IN ('i', 'a')
                        )
        UNION
        -- conversions :
        SELECT
            conname::text AS n_objet,
            pg_roles.rolname AS obj_owner,
            False AS b,
            format('ALTER CONVERSION %I.%I OWNER TO %I',
                n_schema, conname, n_owner) AS commande
            FROM pg_catalog.pg_conversion
                INNER JOIN pg_catalog.pg_roles ON pg_roles.oid = conowner
            WHERE connamespace = quote_ident(n_schema)::regnamespace
                AND NOT conowner = o_owner
        UNION
        -- opérateurs :
        SELECT
            oprname::text AS n_objet,
            pg_roles.rolname AS obj_owner,
            False AS b,
            format('ALTER OPERATOR %s OWNER TO %I',
                pg_operator.oid::regoperator, n_owner) AS commande
            FROM pg_catalog.pg_operator
                INNER JOIN pg_catalog.pg_roles ON pg_roles.oid = oprowner
            WHERE oprnamespace = quote_ident(n_schema)::regnamespace
                AND NOT oprowner = o_owner
        UNION
        -- collations :
        SELECT
            collname::text AS n_objet,
            pg_roles.rolname AS obj_owner,
            False AS b,
            format('ALTER COLLATION %I.%I OWNER TO %I',
                n_schema, collname, n_owner) AS commande
            FROM pg_catalog.pg_collation
                INNER JOIN pg_catalog.pg_roles ON pg_roles.oid = collowner
            WHERE collnamespace = quote_ident(n_schema)::regnamespace
                AND NOT collowner = o_owner
        UNION
        -- text search dictionary :
        SELECT
            dictname::text AS n_objet,
            pg_roles.rolname AS obj_owner,
            False AS b,
            format('ALTER TEXT SEARCH DICTIONARY %s OWNER TO %I',
                pg_ts_dict.oid::regdictionary, n_owner) AS commande
            FROM pg_catalog.pg_ts_dict
                INNER JOIN pg_catalog.pg_roles ON pg_roles.oid = dictowner
            WHERE dictnamespace = quote_ident(n_schema)::regnamespace
                AND NOT dictowner = o_owner
        UNION
        -- text search configuration :
        SELECT
            cfgname::text AS n_objet,
            pg_roles.rolname AS obj_owner,
            False AS b,
            format('ALTER TEXT SEARCH CONFIGURATION %s OWNER TO %I',
                pg_ts_config.oid::regconfig, n_owner) AS commande
            FROM pg_catalog.pg_ts_config
                INNER JOIN pg_catalog.pg_roles ON pg_roles.oid = cfgowner
            WHERE cfgnamespace = quote_ident(n_schema)::regnamespace
                AND NOT cfgowner = o_owner
        -- operator family :
        UNION
        SELECT
            opfname::text AS n_objet,
            pg_roles.rolname AS obj_owner,
            False AS b,
            format('ALTER OPERATOR FAMILY %I.%I USING %I OWNER TO %I',
                n_schema, opfname, amname, n_owner) AS commande
            FROM pg_catalog.pg_opfamily
                INNER JOIN pg_catalog.pg_am ON pg_am.oid = opfmethod
                INNER JOIN pg_catalog.pg_roles ON pg_roles.oid = opfowner
            WHERE opfnamespace = quote_ident(n_schema)::regnamespace
                AND NOT opfowner = o_owner
        -- operator class :
        UNION
        SELECT
            opcname::text AS n_objet,
            pg_roles.rolname AS obj_owner,
            False AS b,
            format('ALTER OPERATOR CLASS %I.%I USING %I OWNER TO %I',
                n_schema, opcname, amname, n_owner) AS commande
            FROM pg_catalog.pg_opclass
                INNER JOIN pg_catalog.pg_am ON pg_am.oid = opcmethod
                INNER JOIN pg_catalog.pg_roles ON pg_roles.oid = opcowner
            WHERE opcnamespace = quote_ident(n_schema)::regnamespace
                AND NOT opcowner = o_owner
            ORDER BY b DESC
    LOOP
        -- choix d'un rôle habilité à exécuter les commandes (sinon
        -- asgard_cherche_executant émet une erreur)
        executant := z_asgard.asgard_cherche_executant(
            'ALTER OBJECT OWNER', 
            new_producteur := n_owner, 
            old_producteur := item.obj_owner
        ) ;
        EXECUTE format('SET ROLE %I', executant) ;
        EXECUTE item.commande ;
        RAISE NOTICE '> %', item.commande ;
        k := k + 1 ;
        EXECUTE format('SET ROLE %I', utilisateur) ;
    END LOOP ;
    
    ------ CATALOGUES CONDITIONNELS ------
    -- soit ceux qui n'existent pas sous toutes les versions de PostgreSQL    
    IF current_setting('server_version_num')::int >= 100000
    THEN
        FOR item IN
            -- extended planner statistics :
            SELECT
                stxname::text AS n_objet,
                pg_roles.rolname AS obj_owner,
                format('ALTER STATISTICS %I.%I OWNER TO %I',
                    n_schema, stxname, n_owner) AS commande
                FROM pg_catalog.pg_statistic_ext
                    INNER JOIN pg_catalog.pg_roles ON pg_roles.oid = stxowner
                WHERE stxnamespace = quote_ident(n_schema)::regnamespace
                    AND NOT stxowner = o_owner        
        LOOP
            -- choix d'un rôle habilité à exécuter les commandes (sinon
            -- asgard_cherche_executant émet une erreur)
            executant := z_asgard.asgard_cherche_executant(
                'ALTER OBJECT OWNER', 
                new_producteur := n_owner, 
                old_producteur := item.obj_owner
            ) ;
            EXECUTE format('SET ROLE %I', executant) ;
            EXECUTE item.commande ;
            RAISE NOTICE '> %', item.commande ;
            k := k + 1 ;
            EXECUTE format('SET ROLE %I', utilisateur) ;
        END LOOP ;
    END IF ;

    ------ RESULTAT ------
    RETURN k ;

EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                            e_hint = PG_EXCEPTION_HINT,
                            e_detl = PG_EXCEPTION_DETAIL,
                            e_errcode = RETURNED_SQLSTATE,
                            e_schema = SCHEMA_NAME ;
    
    RAISE EXCEPTION '%', z_asgard.asgard_prefixe_erreur(e_mssg, 'FAP')
        USING DETAIL = e_detl,
            HINT = e_hint,
            SCHEMA = e_schema,
            ERRCODE = e_errcode ;

END
$_$ ;

ALTER FUNCTION z_asgard.asgard_admin_proprietaire(text, text, boolean)
    OWNER TO g_admin_ext ;

COMMENT ON FUNCTION z_asgard.asgard_admin_proprietaire(text, text, boolean) IS 'ASGARD. Attribue un schéma et tous les objets qu''il contient au propriétaire désigné.' ;


------ 3.4 - TRANSFORMATION GRANT EN REVOKE ------

-- Function: z_asgard.asgard_grant_to_revoke(text)

CREATE OR REPLACE FUNCTION z_asgard.asgard_grant_to_revoke(c_grant text)
    RETURNS text
    LANGUAGE plpgsql
    AS $_$
/* Transforme une commande de type GRANT en son équivalent REVOKE, ou l'inverse.

    Cette fonction ne reconnaît que les mots clés écrits en majuscules et
    échouera si la commande n'est pas de la forme "GRANT [...] TO [...]"
    ou "REVOKE [...] FROM [...]". La commande peut par contre contenir 
    des caractères de remplacement comme '%I', tant que la structure
    générale est correcte.

    Les commandes de la forme "REVOKE XXX OPTION FOR [...]" ne sont pas
    prises en charge. L'attribut "GRANTED BY" non plus.

    L'inverse d'une commande "GRANT [...] WITH XXX" est identique à celui 
    de la commande GRANT standard : une commande REVOKE qui supprimera le 
    privilège avec tous ses attributs.

    Parameters
    ----------
    c_grant : text
        Une commande de type GRANT/REVOKE. "GRANTED BY" et 
        "REVOKE XXX OPTION FOR" ne sont pas autorisés.

    Returns
    -------
    text
        Une commande de type REVOKE/GRANT.

    Raises
    ------
    syntax_error
        FGR1. Si la forme de la commande "c_grant" est incorrecte.
    raise_exception
        FGR2. Si la commande contient "GRANTED BY".
        FGR3. Si la commande est de la forme "REVOKE XXX OPTION FOR".

    Version notes
    -------------
    v1.5.0
        (M) Prise en charge des attributs "GRANT OPTION", "ADMIN OPTION",
            etc. spécifiés avec "WITH" dans les commandes GRANT
            (WITH et tout ce qui suit est omis dans la commande REVOKE 
            renvoyée).
        (M) Meilleur contrôle de la forme des commandes et émission
            d'erreurs pour les formes valides du point de vue de
            PostgreSQL mais non prises en charge par la fonction : 
            "GRANTED BY" et "REVOKE XXX OPTION FOR".
        (m) Amélioration de la gestion des messages d'erreur.
        (d) Enrichissement du descriptif.
     
*/
DECLARE
    c_revoke text ;
    e_mssg text ;
    e_detl text ;
    e_hint text ;
    e_schema text ;
    e_errcode text ;
BEGIN

    ------ FORMES CONNUES NON PRISES EN CHARGE ------
    IF c_grant ~ '\s+GRANTED\s+BY\s+'
    THEN
        RAISE EXCEPTION 'FGR2. "GRANTED BY" n''est pas autorisé dans les commandes GRANT à inverser.'
            USING ERRCODE = 'raise_exception',
                DETAIL = format('commande : %s', c_grant) ;
    ELSIF c_grant ~ '^REVOKE\s+[A-Z]+\s+OPTION\s+FOR\s+'
    THEN
        RAISE EXCEPTION 'FGR3. La forme "REVOKE XXX OPTION FOR" n''est pas inversable.'
            USING ERRCODE = 'raise_exception',
                DETAIL = format('commande : %s', c_grant) ;
    
    ------ GRANT -> REVOKE ------
    ELSIF c_grant ~ '^GRANT\s.*\sTO\s'
    THEN
        c_revoke := regexp_replace(c_grant, '^GRANT', 'REVOKE') ;
        c_revoke := regexp_replace(c_revoke, '\s+TO\s+', ' FROM ') ;
        -- le cas échéant, WITH et tout ce qui suit est supprimé :
        c_revoke := regexp_replace(c_revoke, '\s+WITH\s+.*$', '') ;
    
    ------ REVOKE -> GRANT ------
    ELSIF c_grant ~ '^REVOKE\s.*\sFROM\s'
    THEN
        c_revoke := regexp_replace(c_grant, '^REVOKE', 'GRANT') ;
        c_revoke := regexp_replace(c_revoke, '\s+FROM\s+', ' TO ') ;
    
    ------ FORMES INVALIDES ------
    ELSE
        RAISE EXCEPTION 'FGR1. Commande GRANT/REVOKE invalide.'
            USING ERRCODE = 'syntax_error',
                DETAIL = format('commande : %s', c_grant) ;
    END IF ;
    RETURN c_revoke ;

EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                            e_hint = PG_EXCEPTION_HINT,
                            e_detl = PG_EXCEPTION_DETAIL,
                            e_errcode = RETURNED_SQLSTATE,
                            e_schema = SCHEMA_NAME ;
         
    RAISE EXCEPTION '%', z_asgard.asgard_prefixe_erreur(e_mssg, 'FGR')
        USING DETAIL = e_detl,
            HINT = e_hint,
            SCHEMA = e_schema,
            ERRCODE = e_errcode ;

END
$_$ ;

ALTER FUNCTION z_asgard.asgard_grant_to_revoke(text)
    OWNER TO g_admin_ext ;

COMMENT ON FUNCTION z_asgard.asgard_grant_to_revoke(text) IS 'ASGARD. Transforme une commande GRANT en commande REVOKE.' ;


------ 3.5 - INITIALISATION DE GESTION_SCHEMA ------

-- Function: z_asgard_admin.asgard_initialisation_gestion_schema(text[], boolean)

CREATE OR REPLACE FUNCTION z_asgard_admin.asgard_initialisation_gestion_schema(
    exceptions text[] default NULL::text[], b_gs boolean default False
    )
    RETURNS text
    LANGUAGE plpgsql
    AS $_$
/* Enregistre dans la table de gestion d'Asgard l'ensemble des schémas
   existants encore non référencés, hors schémas système et ceux qui sont
   (optionnellement) listés en argument.

    Parameters
    ----------
    exceptions : text[], optional
        Liste des noms des schémas à omettre, le cas échéant.
    b_gs : boolean, default False
        Un booléen indiquant si, dans l'hypothèse où un schéma serait
        marqué comme non créé dans la table de gestion, c'est le propriétaire
        actuel du schéma qui doit être déclaré comme son producteur (False,
        comportement par défaut) ou si c'est le producteur pré-renseigné dans
        la table de gestion qui doit devenir le propriétaire du schéma (True).
        Ce paramètre est ignoré pour un schéma déjà marqué comme créé. Il vise
        un cas anecdotique où le champ creation de la table de gestion n'est
        pas cohérent avec l'état réel du schéma. La fonction rétablira alors
        le lien entre le schéma et l'enregistrement portant son nom dans la
        table de gestion.
    
    Returns
    -------
    text
        '__ FIN INTIALISATION.' si la requête s'est exécutée normalement.

    Version notes
    -------------
    v1.5.0
        (m) Recours à la fonction asgard_est_schema_systeme pour connaître
            les schémas système à exclure, au lieu d'une liste en dur.
        (m) Recours à asgard_est_actif pour déterminer quels schémas sont
            référencés et actifs, et à asgard_producteur_apparent pour 
            trouver, le cas échéant, un rôle habilité à intervenir sur 
            l'enregistrement.
        (m) Amélioration de la gestion des messages d'erreur.

*/
DECLARE
    item record ;
    e_mssg text ;
    e_detl text ;
    e_hint text ;
    e_schema text ;
    e_errcode text ;
    actif boolean ;
    producteur text ;
    executant text ;
    utilisateur text := current_user ;
BEGIN

    FOR item IN SELECT nspname, nspowner, rolname
        FROM pg_catalog.pg_namespace
            LEFT JOIN pg_catalog.pg_roles ON pg_roles.oid = nspowner
        WHERE NOT z_asgard.asgard_est_schema_systeme(nspname)
            AND (exceptions IS NULL OR NOT nspname = ANY(exceptions))
    LOOP

        SELECT z_asgard.asgard_est_actif(item.nspname) 
            INTO actif ;

        IF actif IS NULL
        -- schéma non référencé dans gestion_schema
        THEN
        
            INSERT INTO z_asgard.gestion_schema_usr (nom_schema, producteur, creation)
                VALUES (item.nspname, item.rolname, True) ;
            RAISE NOTICE '... Schéma % enregistré dans la table de gestion.', item.nspname ;

        ELSIF NOT actif
        -- schéma pré-référencé dans gestion_schema
        THEN

            producteur := z_asgard.asgard_producteur_apparent(n_schema) ;

            -- choix d'un rôle habilité à exécuter les commandes 
            -- (sinon asgard_cherche_executant émet une erreur)
            executant := z_asgard.asgard_cherche_executant(
                'MODIFY GESTION SCHEMA', 
                new_producteur := producteur
            ) ;
            EXECUTE format('SET ROLE %I', executant) ;

            IF NOT b_gs
            THEN
                UPDATE z_asgard.gestion_schema_usr
                    SET creation = True,
                        producteur = item.rolname
                    WHERE item.nspname = nom_schema ;
            ELSE
                UPDATE z_asgard.gestion_schema_usr
                    SET creation = True
                    WHERE item.nspname = nom_schema ;
            END IF ;
            RAISE NOTICE '... Schéma % marqué comme créé dans la table de gestion.', item.nspname ;
        
            EXECUTE format('SET ROLE %I', utilisateur) ;

        END IF ;
    END LOOP ;

    RETURN '__ FIN INITALISATION.' ;

EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                            e_hint = PG_EXCEPTION_HINT,
                            e_detl = PG_EXCEPTION_DETAIL,
                            e_errcode = RETURNED_SQLSTATE,
                            e_schema = SCHEMA_NAME ;
         
    RAISE EXCEPTION '%', z_asgard.asgard_prefixe_erreur(e_mssg, 'FIG')
        USING DETAIL = e_detl,
            HINT = e_hint,
            SCHEMA = e_schema,
            ERRCODE = e_errcode ;

END
$_$ ;

ALTER FUNCTION z_asgard_admin.asgard_initialisation_gestion_schema(text[], boolean)
    OWNER TO g_admin ;

COMMENT ON FUNCTION z_asgard_admin.asgard_initialisation_gestion_schema(text[], boolean) IS 'ASGARD. Enregistre dans la table de gestion d''Asgard l''ensemble des schémas existants encore non référencés, hors schémas système et ceux qui sont (optionnellement) listés en argument.' ;


------ 3.6 - DEREFERENCEMENT D'UN SCHEMA ------

-- Function: z_asgard_admin.asgard_sortie_gestion_schema(text)

CREATE OR REPLACE FUNCTION z_asgard_admin.asgard_sortie_gestion_schema(n_schema text)
    RETURNS text
    LANGUAGE plpgsql
    AS $_$
/* Déréférence de la table de gestion un schéma actif, qui échappera alors aux 
   mécanismes de gestion des droits d'Asgard.
   
    Cette fonction permet d'outrepasser les règles qui veulent que
    seuls les enregistrements de la table de gestion dont le champ "creation"
    vaut False (schémas inactifs) puissent être ciblés par des commandes DELETE, 
    et que ledit champ "creation" ne puisse pas être mis à False si le schéma 
    existe.

    L'intérêt de cette fonction est d'être applicable aux schémas actifs,
    mais elle peut aussi être appliquée à des schémas inactifs. Dans les
    deux cas, l'enregistrement correspondant au schéma est supprimé de la 
    table de gestion.

    Cette fonction n'affecte pas les propriétaires ni les privilèges des
    schémas qu'elle déréférence ou de leurs objets.

    Elle est sans effet sur les schémas qui ne sont pas référencés
    dans la table de gestion, y compris quand ils n'existent pas.

    Parameters
    ----------
    n_schema : text
        Nom d'un schéma présumé référencé dans la table de gestion.

    Returns
    -------
    text
        '__ DEREFERENCEMENT REUSSI.' si la requête s'est exécutée 
        normalement.
        '__ SCHEMA NON REFERENCE.' si le schéma cible n'était pas  
        référencé dans la table de gestion, voire n'existe pas.

    Raises
    ------
    insufficient_privilege
        FSG1. Si le rôle qui exécute la fonction n'hérite pas des droits
        de g_admin.

    Version notes
    -------------
    v1.5.0
        (M) La fonction renvoie désormais '__ SCHEMA NON REFERENCE.' au
            lieu de '__ DEREFERENCEMENT REUSSI.' quand elle n'a pas eu
            besoin de déréférencer le schéma parce qu'il n'était
            pas présent dans la table de gestion.
        (m) Ajout d'un contrôle vérifiant que le rôle qui exécute la
            fonction hérite des privilèges de g_admin.
        (m) Amélioration de la gestion des messages d'erreur.
        (d) Enrichissement du descriptif.        

*/
DECLARE
    e_mssg text ;
    e_hint text ;
    e_detl text ;
    e_errcode text ;
    e_schema text ;
BEGIN

    ------ CONTROLES PREALABLES ------
    -- la fonction est dans z_asgard_admin, donc seuls les membres de
    -- g_admin devraient pouvoir y accéder, mais au cas où :
    IF NOT pg_has_role('g_admin', 'USAGE')
    THEN
        RAISE EXCEPTION 'FSG1. Opération interdite. Vous devez être membre de g_admin pour exécuter cette fonction.'
            USING ERRCODE = 'insufficient_privilege' ;
    END IF ;

    UPDATE z_asgard.gestion_schema_etr
        SET ctrl = ARRAY['EXIT', 'x7-A;#rzo']
        WHERE nom_schema = n_schema ;

    IF FOUND
    THEN
        
        DELETE FROM z_asgard.gestion_schema_etr
            WHERE nom_schema = n_schema ;

        RETURN '__ DEREFERENCEMENT REUSSI.' ;

    ELSE

        RETURN '__ SCHEMA NON REFERENCE.' ;

    END IF ;

EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                            e_hint = PG_EXCEPTION_HINT,
                            e_detl = PG_EXCEPTION_DETAIL,
                            e_errcode = RETURNED_SQLSTATE,
                            e_schema = SCHEMA_NAME ;
    
    RAISE EXCEPTION '%', z_asgard.asgard_prefixe_erreur(e_mssg, 'FSG')
        USING DETAIL = e_detl,
            HINT = e_hint,
            SCHEMA = coalesce(nullif(e_schema, ''), n_schema, '???'),
            ERRCODE = e_errcode ;

END
$_$ ;

ALTER FUNCTION z_asgard_admin.asgard_sortie_gestion_schema(text)
    OWNER TO g_admin ;

COMMENT ON FUNCTION z_asgard_admin.asgard_sortie_gestion_schema(text) IS 'ASGARD. Déréférence un schéma actif de la table de gestion.' ;


------ 3.7 - NETTOYAGE DE LA TABLE DE GESTION ------

-- Function: z_asgard_admin.asgard_nettoyage_oids()

CREATE OR REPLACE FUNCTION z_asgard_admin.asgard_nettoyage_oids()
    RETURNS text
    LANGUAGE plpgsql
    AS $_$
/* Recalcule les OIDs des schémas et rôles référencés dans la table de gestion 
   en fonction de leurs noms.

    Partant du nom de schéma renseigné dans le champ "nom_schema",
    cette fonction corrige les valeurs des champs suivants d'autant que
    de besoin : 
    * "creation" est mis à True si le schéma existe dans la base,
      à False sinon.
    * "oid_schema" est mis à NULL si le schéma n'existe pas, sinon
      sa valeur est actualisée pour correspondre à l'OID du schéma
      de nom "nom_schema".
    * "oid_producteur" est mis à NULL si le schéma n'existe pas,
      sinon sa valeur est actualisée pour correspondre à l'OID du
      rôle propriétaire du schéma de nom "nom_schema".
    * Si le schéma existe, "producteur" est actualisé pour
      correspondre au nom du rôle propriétaire du schéma.
    * "oid_editeur" et "oid_lecteur" sont mis à NULL si le schéma
      n'existe pas. Sinon, et si "editeur" et "lecteur" respectivement
      sont renseignés, ils sont mis à jour avec les OID de ces rôles
      s'ils existent. Si lesdits rôles n'existent pas, les champs
      "oid_editeur" et "editeur" ou "oid_lecteur" et "lecteur" sont
      mis à NULL.

    Cette fonction est en quelque sorte l'inverse de z_asgard.asgard_nettoyage_roles(),
    qui met à jour les noms des rôles en fonction des OID référencés 
    dans la table gestion.

    Returns
    -------
    text
        '__ NETTOYAGE REUSSI.'

    Version notes
    -------------
    v1.5.0
        (m) Amélioration de la gestion des messages d'erreur.

*/
DECLARE
    rec record ;
    e_mssg text ;
    e_detl text ;
    e_hint text ;
    e_schema text ;
    e_errcode text ;
BEGIN

    ALTER TABLE z_asgard_admin.gestion_schema
        DISABLE TRIGGER asgard_on_modify_gestion_schema_before,
        DISABLE TRIGGER asgard_on_modify_gestion_schema_after ;

    FOR rec IN (
        SELECT 
            gestion_schema.nom_schema,
            pg_namespace.oid AS oid_schema,
            pg_namespace.oid IS NOT NULL AS creation,

            CASE WHEN pg_namespace.oid IS NOT NULL
            THEN
                rolowner.rolname 
            ELSE
                gestion_schema.producteur
            END AS producteur,

            pg_namespace.nspowner AS oid_producteur,

            CASE WHEN pg_namespace.oid IS NULL 
                OR gestion_schema.editeur = 'public' 
                OR rolediteur.oid IS NOT NULL
            THEN
                gestion_schema.editeur
            END AS editeur,

            CASE WHEN pg_namespace.oid IS NOT NULL AND gestion_schema.editeur = 'public'
            THEN
                0
            WHEN pg_namespace.oid IS NOT NULL
            THEN
                rolediteur.oid
            END AS oid_editeur,

            CASE WHEN pg_namespace.oid IS NULL
                OR gestion_schema.lecteur = 'public'
                OR rollecteur.oid IS NOT NULL
            THEN
                gestion_schema.lecteur
            END AS lecteur,

            CASE WHEN pg_namespace.oid IS NOT NULL AND gestion_schema.lecteur = 'public'
            THEN
                0
            WHEN pg_namespace.oid IS NOT NULL
            THEN
                rollecteur.oid
            END AS oid_lecteur
            
            FROM z_asgard_admin.gestion_schema
                LEFT JOIN pg_catalog.pg_namespace ON pg_namespace.nspname = gestion_schema.nom_schema
                LEFT JOIN pg_catalog.pg_roles AS rolowner ON rolowner.oid = pg_namespace.nspowner
                LEFT JOIN pg_catalog.pg_roles AS rolediteur ON rolediteur.rolname = gestion_schema.editeur
                LEFT JOIN pg_catalog.pg_roles AS rollecteur ON rollecteur.rolname = gestion_schema.lecteur
    )
    LOOP

        UPDATE z_asgard_admin.gestion_schema
            SET creation = rec.creation,
                oid_schema = rec.oid_schema,
                producteur = rec.producteur,
                oid_producteur = rec.oid_producteur,
                editeur = rec.editeur,
                oid_editeur = rec.oid_editeur,
                lecteur = rec.lecteur,
                oid_lecteur = rec.oid_lecteur
            WHERE gestion_schema.nom_schema = rec.nom_schema ;

    END LOOP ;

    ALTER TABLE z_asgard_admin.gestion_schema
        ENABLE TRIGGER asgard_on_modify_gestion_schema_before,
        ENABLE TRIGGER asgard_on_modify_gestion_schema_after ;

    RETURN '__ NETTOYAGE REUSSI.' ;

EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                            e_hint = PG_EXCEPTION_HINT,
                            e_detl = PG_EXCEPTION_DETAIL,
                            e_errcode = RETURNED_SQLSTATE,
                            e_schema = SCHEMA_NAME ;
         
    RAISE EXCEPTION '%', z_asgard.asgard_prefixe_erreur(e_mssg, 'FNO')
        USING DETAIL = e_detl,
            HINT = e_hint,
            SCHEMA = e_schema,
            ERRCODE = e_errcode ;

END
$_$ ;

ALTER FUNCTION z_asgard_admin.asgard_nettoyage_oids()
    OWNER TO g_admin ;

COMMENT ON FUNCTION z_asgard_admin.asgard_nettoyage_oids() IS 'ASGARD. Recalcule les OIDs des schémas et rôles référencés dans la table de gestion en fonction de leurs noms.' ;


-- Function: z_asgard.asgard_nettoyage_roles()

CREATE OR REPLACE FUNCTION z_asgard.asgard_nettoyage_roles()
    RETURNS text
    LANGUAGE plpgsql
    AS $_$
/* Active la mise à jour des noms des rôles désignés dans la table 
   de gestion comme producteur, éditeur et lecteur, pour prendre 
   en compte les changements de nom ou suppression qui auraient pu 
   avoir eu lieu.

    Indirectement, elle assure aussi que g_admin soit membre de tous les 
    rôles producteurs non super-utilisateurs.

    La fonction ne traite que les enregistrements visibles de l'utilisateur
    dans la vue z_asgard.gestion_schema_usr. Seul le rôle g_admin
    est assuré de nettoyer l'ensemble de la table de gestion.

    Returns
    -------
    text
        '__ NETTOYAGE REUSSI.' si la requête s'est exécutée normalement.

    Notes
    -----
    Cette fonction a essentiellement pour effet de réactiver les
    déclencheurs sur la table gestion_schema, et ce sont eux qui 
    effectuent le nettoyage.

    Version notes
    -------------
    v1.5.0
        (m) Amélioration de la gestion des messages d'erreur.
        (d) Enrichissement du descriptif.

*/
DECLARE
    e_mssg text ;
    e_detl text ;
    e_hint text ;
    e_errcode text ;
    e_schema text ;
BEGIN

    UPDATE z_asgard.gestion_schema_usr
        SET producteur = producteur,
            editeur = editeur,
            lecteur = lecteur ;

    RETURN '__ NETTOYAGE REUSSI.' ;

EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                            e_hint = PG_EXCEPTION_HINT,
                            e_detl = PG_EXCEPTION_DETAIL,
                            e_errcode = RETURNED_SQLSTATE,
                            e_schema = SCHEMA_NAME ;
    
    RAISE EXCEPTION '%', z_asgard.asgard_prefixe_erreur(e_mssg, 'FNR')
        USING DETAIL = e_detl,
            HINT = e_hint,
            SCHEMA = e_schema,
            ERRCODE = e_errcode ;

END
$_$ ;

ALTER FUNCTION z_asgard.asgard_nettoyage_roles()
    OWNER TO g_admin_ext ;

COMMENT ON FUNCTION z_asgard.asgard_nettoyage_roles() IS 'ASGARD. Active la mise à jour des noms des rôles référencés dans la table de gestion.' ;


------ 3.8 - REINITIALISATION DES PRIVILEGES SUR UN SCHEMA ------

-- Function: z_asgard.asgard_initialise_schema(text, boolean, boolean)

CREATE OR REPLACE FUNCTION z_asgard.asgard_initialise_schema(
    n_schema text,
    b_preserve boolean DEFAULT False,
    b_gs boolean default False
)
    RETURNS text
    LANGUAGE plpgsql
    AS $_$
/* Réinitialise les droits sur un schéma et ses objets selon les privilèges
   standards du producteur, de l'éditeur et du lecteur désignés dans la table
   de gestion d'Asgard.

    Elle a notamment pour effet de révoquer tout privilège accordé à 
    d'autres rôles que le producteur et les éventuels éditeur et lecteur.

    Si cette fonction est appliquée à un schéma actif non référencé
    dans la table de gestion, elle l'y ajoute, avec son propriétaire
    courant comme producteur.

    La fonction échouera si le schéma n'existe pas.

    Elle échouera également si elle est appliquée à un schéma considéré par 
    Asgard  comme un schéma système, à l'exception notable de "z_asgard_admin". 
    Elle ne référencera pas ce schéma, mais saura rétablir les droits nécessaires
    au fonctionnement d'Asgard et supprimer les privilèges excédentaires.
    "z_asgard" n'étant pour sa part pas considéré comme un schéma système,
    elle le référencera s'il ne l'était pas encore et réinitialisera les 
    droits en prenant à la fois en compte les privilèges nécessaires à Asgard et 
    ceux qui sont attendus pour les éventuels rôles éditeur et lecteur spécifiés
    pour ce schéma dans la table de gestion.

    Parameters
    ----------
    n_schema : text
        Nom d'un schéma présumé existant.
    b_preserve : boolean, default False
        Pour un schéma encore non référencé ou pré-référencé comme non créé
        dans la table de gestion, une valeur True signifie que les privilèges
        des rôles lecteur et éditeur doivent être ajoutés par dessus les droits
        actuels. Avec la valeur par défaut False, les privilèges sont
        réinitialisés avant application des droits standards. Ce paramètre est
        ignoré pour un schéma déjà référencé comme créé - les privilèges sont
        alors quoi qu'il arrive réinitialisés.
    b_gs : boolean, default False
        Un booléen indiquant si, dans l'hypothèse où le schéma serait
        marqué comme non créé dans la table de gestion, c'est le propriétaire
        actuel du schéma qui doit être déclaré comme son producteur (False,
        comportement par défaut) ou si c'est le producteur pré-renseigné dans
        la table de gestion qui doit devenir le propriétaire du schéma (True).
        Ce paramètre est ignoré pour un schéma déjà marqué comme créé. Il vise
        un cas anecdotique où le champ creation de la table de gestion n'est
        pas cohérent avec l'état réel du schéma. La fonction rétablira alors
        le lien entre le schéma et l'enregistrement portant son nom dans la
        table de gestion.
    
    Returns
    -------
    text
        '__ REINITIALISATION REUSSIE.' (ou '__INITIALISATION REUSSIE.' pour
        un schéma non référencé comme créé avec b_preserve = True) si la
        requête s'est exécutée normalement.

    Raises
    ------
    invalid_parameter_value
        FIS1. Si le schéma est considéré par Asgard comme un schéma système,
        hors z_asgard_admin.
        FIS2. Si le schéma n'existe pas.

    Version notes
    -------------
    v1.5.0
        (M) Prise en compte du fait que le schéma z_asgard_admin
            est désormais considéré comme un schéma système non 
            référençable. La fonction reste capable de réinitialiser
            les droits sur ce schéma mais ne tente plus de le référencer.
        (M) Prise en compte des privilèges de g_admin_ext sur la table
            de configuration z_asgard_admin.asgard_configuration.
        (M) Recours à asgard_cherche_executant pour trouver des 
            rôles habilités, le cas échéant, à modifier les 
            propriétaires des objets et/ou leurs privilèges.
            Le contrôle des permissions de l'utilisateur est dorénavant 
            entièrement délégué à cette fonction, le cas échéant par
            l'intermédiaire de asgard_admin_proprietaire.
        (M) Recours à asgard_cherche_executant et 
            asgard_producteur_apparent pour, dans le cas d'un schéma
            référencé comme inactif dans la table de gestion, trouver 
            un rôle habilité à mettre à jour l'enregistrement.
        (m) Recours à la fonction asgard_est_schema_systeme pour connaître
            les schémas système à exclure, au lieu d'une liste en dur.
        (m) Recours à asgard_est_actif pour déterminer si le schéma
            considéré est référencé et actif.
        (m) Recours à asgard_information pour récupérer les rôles 
            producteur, éditeur et lecteur du schéma.
        (m) Amélioration de la gestion des messages d'erreur.
        (d) Enrichissement du descriptif.

*/
DECLARE
    roles record ;
    actif boolean ;
    r record ;
    c record ;
    item record ;
    n_owner text ;
    k int := 0 ;
    n int ;
    e_mssg text ;
    e_detl text ;
    e_hint text ;
    e_schema text ;
    e_errcode text ;
    producteur text ;
    executant text ;
    utilisateur text := current_user ;
BEGIN
    ------ TESTS PREALABLES ------
    -- schéma système, sauf z_asgard_admin
    IF z_asgard.asgard_est_schema_systeme(n_schema) AND NOT n_schema = 'z_asgard_admin'
    THEN
        RAISE EXCEPTION 'FIS1. Opération interdite. Le schéma % est un schéma système.', n_schema
            USING ERRCODE = 'invalid_parameter_value',
                SCHEMA = n_schema ;
    END IF ;
    
    -- existence du schéma
    SELECT rolname INTO n_owner
        FROM pg_catalog.pg_namespace
            LEFT JOIN pg_catalog.pg_roles ON pg_roles.oid = nspowner
        WHERE n_schema = nspname ;
    IF NOT FOUND
    THEN
        RAISE EXCEPTION 'FIS2. Echec. Le schéma % n''existe pas.', n_schema
            USING ERRCODE = 'invalid_parameter_value',
                SCHEMA = n_schema ;
    END IF ;
    
    ------ SCHEMA DEJA REFERENCE ? ------
    actif := z_asgard.asgard_est_actif(n_schema) ;
    -- toujours NULL si le schéma n'est pas référencé
    
    ------ SCHEMA NON REFERENCE ------
    -- ajouté à gestion_schema si ce n'est pas z_asgard_admin
    -- le reste sera alors pris en charge par le trigger
    -- on_modify_gestion_schema_after
    IF actif IS NULL AND NOT n_schema = 'z_asgard_admin'
    THEN

        INSERT INTO z_asgard.gestion_schema_usr (nom_schema, producteur, creation)
            VALUES (n_schema, n_owner, true) ;
        RAISE NOTICE '... Le schéma % a été enregistré dans la table de gestion.', n_schema ;
        
        IF b_preserve
        THEN
            RETURN '__ INITIALISATION REUSSIE.' ;
        END IF ;
        
    ------- SCHEMA PRE-REFERENCE ------
    -- présent dans gestion_schema avec creation valant
    -- False.
    ELSIF NOT actif
    THEN

        producteur := z_asgard.asgard_producteur_apparent(n_schema) ;
        -- ne peut pas être nul si le schéma est référencé

        -- choix d'un rôle habilité à exécuter les commandes (sinon
        -- asgard_cherche_executant émet une erreur)
        executant := z_asgard.asgard_cherche_executant(
            'MODIFY GESTION SCHEMA', 
            new_producteur := producteur
        ) ;
        EXECUTE format('SET ROLE %I', executant) ;

        IF NOT b_gs
        THEN
            UPDATE z_asgard.gestion_schema_usr
                SET creation = true,
                    producteur = n_owner
                WHERE n_schema = nom_schema ;
        ELSE
            UPDATE z_asgard.gestion_schema_usr
                SET creation = true
                WHERE n_schema = nom_schema ;
        END IF ;
        RAISE NOTICE '... Le schéma % a été marqué comme créé dans la table de gestion.', n_schema ;
        
        EXECUTE format('SET ROLE %I', utilisateur) ;

        IF b_preserve
        THEN
            RETURN '__ INITIALISATION REUSSIE.' ;
        END IF ;
    
    END IF ;
        
    ------ RECUPERATION DES ROLES ------
    SELECT info.producteur, info.editeur, info.lecteur INTO roles
        FROM z_asgard.asgard_information(
            n_schema,
            consolide_roles := True
        ) AS info ;
        
    ------ REMISE A PLAT DES PROPRIETAIRES ------
    -- uniquement pour les schémas qui étaient déjà
    -- référencés dans gestion_schema (pour les autres, pris en charge
    -- par le trigger on_modify_gestion_schema_after)
    
    -- schéma dont le propriétaire ne serait pas le producteur
    IF actif
    THEN
        IF NOT roles.producteur = n_owner
        THEN

            -- propriétaire du schéma + contenu
            RAISE NOTICE '(ré)attribution de la propriété du schéma et des objets au rôle producteur du schéma :' ;
            PERFORM z_asgard.asgard_admin_proprietaire(n_schema, roles.producteur) ;
        
        -- schema dont le propriétaire est le producteur
        ELSE

            -- reprise uniquement des propriétaires du contenu
            RAISE NOTICE '(ré)attribution de la propriété des objets au rôle producteur du schéma :' ;
            SELECT z_asgard.asgard_admin_proprietaire(n_schema, roles.producteur, False) INTO n ;
            IF n = 0
            THEN
                RAISE NOTICE '> néant' ;
            END IF ;
          
        END IF ;
    END IF ;
    
    ------ DESTRUCTION DES PRIVILEGES ACTUELS ------
    -- hors privilèges par défaut (définis par ALTER DEFAULT PRIVILEGE)
    -- et hors révocations des privilèges par défaut de public sur
    -- les types et les fonctions
    -- pour le propriétaire, ces commandes ont pour effet
    -- de remettre les privilèges par défaut supprimés

    -- choix d'un rôle habilité à exécuter les commandes (sinon
    -- asgard_cherche_executant émet une erreur)
    executant := z_asgard.asgard_cherche_executant(
        'PRIVILEGES', 
        new_producteur := n_owner
    ) ;
    EXECUTE format('SET ROLE %I', executant) ;
    
    -- public
    RAISE NOTICE 'remise à zéro des privilèges manuels du pseudo-rôle public :' ;
    FOR c IN (SELECT * FROM z_asgard.asgard_synthese_public(
                    quote_ident(n_schema)::regnamespace))
    LOOP
        EXECUTE format(z_asgard.asgard_grant_to_revoke(c.commande), 'public') ;
        RAISE NOTICE '> %', format(z_asgard.asgard_grant_to_revoke(c.commande), 'public') ;
    END LOOP ;
    IF NOT FOUND
    THEN
        RAISE NOTICE '> néant' ;
    END IF ;
    
    -- autres rôles
    RAISE NOTICE 'remise à zéro des privilèges des autres rôles (pour le producteur, les éventuels privilèges manquants sont réattribués) :' ;
    FOR r IN (SELECT rolname FROM pg_roles)
    LOOP
        FOR c IN (SELECT * FROM z_asgard.asgard_synthese_role(
                       quote_ident(n_schema)::regnamespace, quote_ident(r.rolname)::regrole))
        LOOP
            EXECUTE format(z_asgard.asgard_grant_to_revoke(c.commande), r.rolname) ;
            RAISE NOTICE '> %', format(z_asgard.asgard_grant_to_revoke(c.commande), r.rolname) ;
            k := k + 1 ;
        END LOOP ;        
    END LOOP ;
    IF NOT FOUND OR k = 0
    THEN
        RAISE NOTICE '> néant' ;
    END IF ;

    ------ RECREATION DES PRIVILEGES DE L'EDITEUR ------
    IF roles.editeur IS NOT NULL
    THEN
        RAISE NOTICE 'application des privilèges standards pour le rôle éditeur du schéma :' ;
        
        EXECUTE format('GRANT USAGE ON SCHEMA %I TO %I', n_schema, roles.editeur) ;
        RAISE NOTICE '> %', format('GRANT USAGE ON SCHEMA %I TO %I', n_schema, roles.editeur) ;
        
        EXECUTE format('GRANT SELECT, UPDATE, DELETE, INSERT ON ALL TABLES IN SCHEMA %I TO %I', n_schema, roles.editeur) ;
        RAISE NOTICE '> %', format('GRANT SELECT, UPDATE, DELETE, INSERT ON ALL TABLES IN SCHEMA %I TO %I', n_schema, roles.editeur) ;
        
        EXECUTE format('GRANT SELECT, USAGE ON ALL SEQUENCES IN SCHEMA %I TO %I', n_schema, roles.editeur) ;
        RAISE NOTICE '> %', format('GRANT SELECT, USAGE ON ALL SEQUENCES IN SCHEMA %I TO %I', n_schema, roles.editeur) ;
    END IF ;
    
    ------ RECREATION DES PRIVILEGES DU LECTEUR ------
    IF roles.lecteur IS NOT NULL
    THEN
        RAISE NOTICE 'application des privilèges standards pour le rôle lecteur du schéma :' ;
        
        EXECUTE format('GRANT USAGE ON SCHEMA %I TO %I', n_schema, roles.lecteur) ;
        RAISE NOTICE '> %', format('GRANT USAGE ON SCHEMA %I TO %I', n_schema, roles.lecteur) ;
        
        EXECUTE format('GRANT SELECT ON ALL TABLES IN SCHEMA %I TO %I', n_schema, roles.lecteur) ;
        RAISE NOTICE '> %', format('GRANT SELECT ON ALL TABLES IN SCHEMA %I TO %I', n_schema, roles.lecteur) ;
        
        EXECUTE format('GRANT SELECT ON ALL SEQUENCES IN SCHEMA %I TO %I', n_schema, roles.lecteur) ;
        RAISE NOTICE '> %', format('GRANT SELECT ON ALL SEQUENCES IN SCHEMA %I TO %I', n_schema, roles.lecteur) ;
    END IF ;
    
    ------ RECREATION DES PRIVILEGES SUR LES SCHEMAS D'ASGARD ------
    IF n_schema = 'z_asgard'
    THEN
        -- rétablissement des droits de public
        RAISE NOTICE 'rétablissement des privilèges attendus pour le pseudo-rôle public :' ;
        
        GRANT USAGE ON SCHEMA z_asgard TO public ;
        RAISE NOTICE '> GRANT USAGE ON SCHEMA z_asgard TO public' ;
        
        GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE z_asgard.gestion_schema_usr TO public ;
        RAISE NOTICE '> GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE z_asgard.gestion_schema_usr TO public' ;
        
        GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE z_asgard.gestion_schema_etr TO public ;
        RAISE NOTICE '> GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE z_asgard.gestion_schema_etr TO public' ;
                
        GRANT SELECT ON TABLE z_asgard.asgardmenu_metadata TO public ;
        RAISE NOTICE '> GRANT SELECT ON TABLE z_asgard.asgardmenu_metadata TO public' ;
        
        GRANT SELECT ON TABLE z_asgard.asgardmanager_metadata TO public ;
        RAISE NOTICE '> GRANT SELECT ON TABLE z_asgard.asgardmanager_metadata TO public' ;
        
        GRANT SELECT ON TABLE z_asgard.gestion_schema_read_only TO public ;
        RAISE NOTICE '> GRANT SELECT ON TABLE z_asgard.gestion_schema_read_only TO public' ;
    
    ELSIF n_schema = 'z_asgard_admin'
    THEN
        -- rétablissement des droits de g_admin_ext
        RAISE NOTICE 'rétablissement des privilèges attendus pour g_admin_ext :' ;
        
        GRANT USAGE ON SCHEMA z_asgard_admin TO g_admin_ext ;
        RAISE NOTICE '> GRANT USAGE ON SCHEMA z_asgard_admin TO g_admin_ext' ;
        
        GRANT INSERT, SELECT, UPDATE, DELETE ON TABLE z_asgard_admin.gestion_schema TO g_admin_ext ;
        RAISE NOTICE '> GRANT INSERT, SELECT, UPDATE, DELETE ON TABLE z_asgard_admin.gestion_schema TO g_admin_ext' ;

        GRANT SELECT ON TABLE z_asgard_admin.asgard_configuration TO g_admin_ext ;
        RAISE NOTICE '> GRANT SELECT ON TABLE z_asgard_admin.asgard_configuration TO g_admin_ext' ;
        
    END IF ;

    EXECUTE format('SET ROLE %I', utilisateur) ;
    
    ------ ACL PAR DEFAUT ------
    k := 0 ;
    RAISE NOTICE 'suppression des privilèges par défaut :' ;
    FOR item IN (
        SELECT
            format(
                'ALTER DEFAULT PRIVILEGES FOR ROLE %s IN SCHEMA %s REVOKE %s ON %s FROM %s',
                pg_default_acl.defaclrole::regrole,
                pg_default_acl.defaclnamespace::regnamespace,
                -- impossible que defaclnamespace vaille 0 (privilège portant
                -- sur tous les schémas) ici, puisque c'est l'OID de n_schema
                acl.privilege,
                t.typ_lg,
                CASE WHEN acl.grantee = 0 THEN 'public' ELSE acl.grantee::regrole::text END
            ) AS commande,
            pg_roles.rolname,
            pg_default_acl.defaclrole
            FROM pg_catalog.pg_default_acl 
                INNER JOIN pg_catalog.pg_roles 
                    ON pg_default_acl.defaclrole = pg_roles.oid,
                aclexplode(pg_default_acl.defaclacl) AS acl (
                    grantor, grantee, privilege, grantable
                ),
                unnest(
                    ARRAY['TABLES', 'SEQUENCES',
                        CASE WHEN current_setting('server_version_num')::int < 110000
                            THEN 'FUNCTIONS' ELSE 'ROUTINES' END,
                        -- à ce stade FUNCTIONS et ROUTINES sont équivalents, mais
                        -- ROUTINES est préconisé
                        'TYPES', 'SCHEMAS'],
                    ARRAY['r', 'S', 'f', 'T', 'n']
                ) AS t (typ_lg, typ_crt)
            WHERE pg_default_acl.defaclnamespace = quote_ident(n_schema)::regnamespace
                AND pg_default_acl.defaclobjtype = t.typ_crt
        )
    LOOP

        -- choix d'un rôle habilité à exécuter les commandes (sinon
        -- asgard_cherche_executant émet une erreur)
        executant := z_asgard.asgard_cherche_executant(
            'ALTER DEFAULT PRIVILEGES', 
            new_producteur := item.rolname
        ) ;
        EXECUTE format('SET ROLE %I', executant) ;
        EXECUTE item.commande ;
        RAISE NOTICE '> %', item.commande ;
        EXECUTE format('SET ROLE %I', utilisateur) ;

        k := k + 1 ;

    END LOOP ;

    IF k = 0
    THEN
        RAISE NOTICE '> néant' ;
    END IF ;
    
    RETURN '__ REINITIALISATION REUSSIE.' ;
    
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                            e_hint = PG_EXCEPTION_HINT,
                            e_detl = PG_EXCEPTION_DETAIL,
                            e_errcode = RETURNED_SQLSTATE,
                            e_schema = SCHEMA_NAME ;
    
    RAISE EXCEPTION '%', z_asgard.asgard_prefixe_erreur(e_mssg, 'FIS')
        USING DETAIL = e_detl,
            HINT = e_hint,
            SCHEMA = e_schema,
            ERRCODE = e_errcode ;
    
END
$_$ ;

ALTER FUNCTION z_asgard.asgard_initialise_schema(text, boolean, boolean)
    OWNER TO g_admin_ext ;

COMMENT ON FUNCTION z_asgard.asgard_initialise_schema(text, boolean, boolean) IS 'ASGARD. Réinitialise les droits sur un schéma et ses objets selon les privilèges standards du producteur, de l''éditeur et du lecteur désignés dans la table de gestion d''Asgard.' ;


------ 3.9 - REINITIALISATION DES PRIVILEGES SUR UN OBJET ------

-- Function: z_asgard.asgard_initialise_obj(text, text, text)

CREATE OR REPLACE FUNCTION z_asgard.asgard_initialise_obj(
    obj_schema text,
    obj_nom text,
    obj_typ text
)
    RETURNS text
    LANGUAGE plpgsql
    AS $_$
/* Réinitialise les droits sur un objet selon les privilèges standards
   associés aux rôles désignés dans la table de gestion pour son schéma.

   Cette fonction échouera si le schéma de l'objet n'est pas un schéma
   actif référencé dans la table de gestion d'Asgard.

   Elle ne peut pas être appliquée aux objets des schémas d'Asgard. Pour
   réinitialiser les droits sur ceux-ci, il faudra nécessairement recourir
   à la fonction z_asgard.asgard_initialise_schema et traiter le schéma
   dans sa globalité.

    Parameters
    ----------
    obj_schema : text
        Le nom du schéma contenant l'objet.
    obj_nom : text
        Le nom de l'objet. À écrire sans les guillemets des identifiants
        PostgreSQL SAUF pour les fonctions, dont le nom doit impérativement
        être entre guillemets s'il ne respecte pas les conventions de
        nommage des identifiants PostgreSQL.
    obj_typ : {
        'table', 'partitioned table', 'view', 'materialized view', 
        'foreign table', 'sequence', 'function', 'aggregate', 'procedure', 
        'routine', 'type', 'domain'
    }
        Le type de l'objet. Pour les tables partitionnées, les types 'table'
        et 'partitioned table' sont acceptés.

    Returns
    -------
    text
        '__ REINITIALISATION REUSSIE.' si la requête s'est exécutée normalement.

    Raises
    ------
    invalid_parameter_value
        FIO1. Si le schéma est considéré par Asgard comme un schéma système.
        FIO2. Si le schéma de l'objet (obj_schema) n'est pas référencé.
        FIO3. Si le type obj_typ n'est pas reconnu.
        FIO4. S'il n'existe pas d'objet obj_nom dans le schéma obj_schema.
        FIO6. Si le schéma de l'objet (obj_schema) est référencé, mais pas en
        tant que schéma actif.
    raise_exception
        FIO5. Si l'objet est rattaché au schéma "z_asgard", et que ce dernier
        est référencé (sinon l'erreur FIO2 sera émise).

    Version notes
    -------------
    v1.5.0
        (M) La fonction renvoie désormais une erreur lorsqu'elle est
            appliquée à un objet du schéma z_asgard, faute d'assurer la
            préservation des privilèges nécessaires au fonctionnement
            d'Asgard.
        (M) Recours à asgard_cherche_executant pour trouver des 
            rôles habilités, le cas échéant, à modifier les 
            propriétaires des objets et/ou leurs privilèges.
            Le contrôle des permissions de l'utilisateur est dorénavant 
            entièrement délégué à cette fonction, le cas échéant par
            l'intermédiaire de asgard_admin_proprietaire.
        (m) Recours à asgard_est_actif pour déterminer si le schéma
            de l'objet est référencé et actif. Des erreurs distinctes
            sont désormais renvoyées si le schéma n'est pas référencé
            (FIO2) ou n'est pas actif (FIO6).
        (m) Recours à asgard_information pour récupérer les rôles
            producteur, éditeur et lecteur du schéma de l'objet.
        (m) Recours à la fonction asgard_est_schema_systeme pour connaître
            les schémas système à exclure, au lieu d'une liste en dur.
        (m) Amélioration de la gestion des messages d'erreur.

*/
DECLARE
    class_info record ;
    roles record ;
    obj record ;
    r record ;
    c record ;
    l text ;
    k int := 0 ;
    e_mssg text ;
    e_detl text ;
    e_hint text ;
    e_schema text ;
    e_errcode text ;
    executant text ;
    utilisateur text := current_user ;
    actif boolean ;
BEGIN

    -- pour la suite, on assimile les partitions à des tables
    IF obj_typ = 'partitioned table'
    THEN
        obj_typ := 'table' ;
    ELSIF obj_typ = ANY (ARRAY['routine', 'procedure', 'function', 'aggregate'])
    THEN
        -- à partir de PG11, les fonctions et procédures sont des routines
        IF current_setting('server_version_num')::int >= 110000
        THEN
            obj_typ := 'routine' ;
        -- pour les versions antérieures, les routines et procédures n'existent
        -- théoriquement pas, mais on considère que ces mots-clés désignent
        -- des fonctions
        ELSE
            obj_typ := 'function' ;
        END IF ;
    END IF ;

    ------ TESTS PREALABLES ------
    -- schéma système
    IF z_asgard.asgard_est_schema_systeme(obj_schema)
    THEN
        RAISE EXCEPTION 'FIO1. Opération interdite. Le schéma % est un schéma système.', obj_schema
            USING ERRCODE = 'invalid_parameter_value',
                SCHEMA = obj_schema ;
    END IF ;
    
    -- schéma non référencé
    actif := z_asgard.asgard_est_actif(obj_schema) ;

    IF actif is NULL
    THEN
        RAISE EXCEPTION 'FIO2. Echec. Le schéma % n''est pas référencé dans la table de gestion d''Asgard.', obj_schema
            USING ERRCODE = 'invalid_parameter_value',
                SCHEMA = obj_schema ;
    ELSIF NOT actif
    THEN
        RAISE EXCEPTION 'FIO6. Echec. Le schéma % n''est pas référencé en tant que schéma actif dans la table de gestion d''Asgard.', obj_schema
            USING ERRCODE = 'invalid_parameter_value',
                SCHEMA = obj_schema ;
    END IF ;

    -- z_asgard - notamment pour ne pas effacer les privilèges du pseudo-rôle public
    IF obj_schema = 'z_asgard'
    THEN
        RAISE EXCEPTION 'FIO5. Opération interdite. Cette fonction n''est pas applicable aux objets du schéma z_asgard.'
            USING ERRCODE = 'raise_exception',
                SCHEMA = obj_schema,
                HINT = 'Vous pouvez utiliser la fonction z_asgard.asgard_initialise_schema pour réinitialiser les droits sur le schéma z_asgard dans sa globalité, incluant l''objet considéré.' ;
    END IF ;
    
    -- type invalide + récupération des informations sur le catalogue contenant l'objet
    SELECT
        xtyp, xclass, xreg,
        format('%sname', xprefix) AS xname,
        format('%sowner', xprefix) AS xowner,
        format('%snamespace', xprefix) AS xschema
        INTO class_info
        FROM unnest(
                ARRAY['table', 'foreign table', 'view', 'materialized view',
                    'sequence', 'type', 'domain', 'function', 'routine'],
                ARRAY['pg_class', 'pg_class', 'pg_class', 'pg_class',
                    'pg_class', 'pg_type', 'pg_type', 'pg_proc', 'pg_proc'],
                ARRAY['rel', 'rel', 'rel', 'rel', 'rel', 'typ', 'typ',
                    'pro', 'pro'],
                ARRAY['regclass', 'regclass', 'regclass', 'regclass', 'regclass',
                    'regtype', 'regtype', 'regprocedure', 'regprocedure']
                ) AS typ (xtyp, xclass, xprefix, xreg)
            WHERE typ.xtyp = obj_typ ;
            
    IF NOT FOUND
    THEN
        RAISE EXCEPTION 'FIO3. Echec. Le type % n''existe pas ou n''est pas pris en charge.', obj_typ
            USING HINT = 'Types acceptés : ''table'', ''partitioned table'', ''view'', ''materialized view'', ''foreign table'', ''sequence'', ''function'', ''aggregate'', ''routine'', ''procedure'', ''type'', ''domain''.',
                ERRCODE = 'invalid_parameter_value' ;
    END IF ;
        
    -- objet inexistant + récupération du propriétaire
    EXECUTE 'SELECT pg_roles.rolname, '
            || class_info.xclass || '.oid, '
            || CASE WHEN class_info.xclass = 'pg_type'
                    THEN quote_literal(quote_ident(obj_schema) || '.' || quote_ident(obj_nom)) || '::text'
                ELSE class_info.xclass || '.oid::' || class_info.xreg || '::text'
                END || ' AS appel'
            || ' FROM pg_catalog.' || class_info.xclass
            || '     INNER JOIN pg_catalog.pg_roles ON pg_roles.oid = ' || class_info.xowner
            || ' WHERE ' || CASE WHEN class_info.xclass = 'pg_proc'
                    THEN class_info.xclass || '.oid = '
                        || quote_literal(quote_ident(obj_schema) || '.' || obj_nom)
                        || '::regprocedure'
                ELSE class_info.xname || ' = ' || quote_literal(obj_nom)
                    || ' AND ' || class_info.xschema || '::regnamespace::text = '
                    || quote_literal(quote_ident(obj_schema)) END
        INTO obj ;
            
    IF obj.rolname IS NULL
    THEN
        RAISE EXCEPTION 'FIO4. Echec. L''objet % n''existe pas.', obj_nom
            ERRCODE = 'invalid_parameter_value' ;
    END IF ;    
    
    ------ RECUPERATION DES ROLES ------
    SELECT info.producteur, info.editeur, info.lecteur INTO roles
        FROM z_asgard.asgard_information(
            obj_schema,
            consolide_roles := True
        ) AS info ;
    
    ------ REMISE A PLAT DU PROPRIETAIRE ------
    IF NOT obj.rolname = roles.producteur
    THEN

        -- choix d'un rôle habilité à exécuter les commandes (sinon
        -- asgard_cherche_executant émet une erreur)
        executant := z_asgard.asgard_cherche_executant(
            'ALTER OBJECT OWNER', 
            new_producteur := roles.producteur,
            old_producteur := obj.rolname
        ) ;
        EXECUTE format('SET ROLE %I', executant) ;

        RAISE NOTICE 'réattribution de la propriété de % au rôle producteur du schéma :', obj_nom ;
        l := format('ALTER %s %s OWNER TO %I', obj_typ, obj.appel, roles.producteur) ;
        EXECUTE l ;
        RAISE NOTICE '> %', l ;

        EXECUTE format('SET ROLE %I', utilisateur) ;

    END IF ;
    
    ------ DESTRUCTION DES PRIVILEGES ACTUELS ------
    -- hors privilèges par défaut (définis par ALTER DEFAULT PRIVILEGE)
    -- et hors révocations des privilèges par défaut de public sur
    -- les types et les fonctions
    -- pour le propriétaire, ces commandes ont pour effet
    -- de remettre les privilèges par défaut supprimés

    -- choix d'un rôle habilité à exécuter les commandes (sinon
    -- asgard_cherche_executant émet une erreur)
    executant := z_asgard.asgard_cherche_executant(
        'PRIVILEGES', 
        new_producteur := roles.producteur
    ) ;
    EXECUTE format('SET ROLE %I', executant) ;
    
    -- public
    IF obj_typ IN ('table', 'view', 'materialized view', 'sequence',
            'foreign table', 'partitioned table')
    THEN
        RAISE NOTICE 'remise à zéro des privilèges manuels du pseudo-rôle public :' ;
        FOR c IN (SELECT * FROM z_asgard.asgard_synthese_public_obj(obj.oid, obj_typ))
        LOOP
            EXECUTE format(z_asgard.asgard_grant_to_revoke(c.commande), 'public') ;
            RAISE NOTICE '> %', format(z_asgard.asgard_grant_to_revoke(c.commande), 'public') ;
        END LOOP ;
        IF NOT FOUND
        THEN
            RAISE NOTICE '> néant' ;
        END IF ;
    END IF ;

    -- autres rôles
    RAISE NOTICE 'remise à zéro des privilèges des autres rôles (pour le producteur, les éventuels privilèges manquants sont réattribués) :' ;
    FOR r IN (SELECT rolname FROM pg_roles)
    LOOP
        FOR c IN (SELECT * FROM z_asgard.asgard_synthese_role_obj(
                        obj.oid, obj_typ, quote_ident(r.rolname)::regrole))
        LOOP
            EXECUTE format(z_asgard.asgard_grant_to_revoke(c.commande), r.rolname) ;
            RAISE NOTICE '> %', format(z_asgard.asgard_grant_to_revoke(c.commande), r.rolname) ;
            k := k + 1 ;
        END LOOP ;        
    END LOOP ;
    IF NOT FOUND OR k = 0
    THEN
        RAISE NOTICE '> néant' ;
    END IF ;

    ------ RECREATION DES PRIVILEGES DE L'EDITEUR ------
    IF roles.editeur IS NOT NULL
    THEN
        -- sur les tables :
        IF obj_typ IN ('table', 'view', 'materialized view', 'foreign table')
        THEN
            RAISE NOTICE 'application des privilèges standards pour le rôle éditeur du schéma :' ;
            l := format('GRANT SELECT, UPDATE, DELETE, INSERT ON TABLE %I.%I TO %I',
                obj_schema, obj_nom, roles.editeur) ;
            EXECUTE l ;
            RAISE NOTICE '> %', l ;
        -- sur les séquences :
        ELSIF obj_typ IN ('sequence')
        THEN
            RAISE NOTICE 'application des privilèges standards pour le rôle éditeur du schéma :' ;
            l := format('GRANT SELECT, USAGE ON SEQUENCE %I.%I TO %I',
                obj_schema, obj_nom, roles.editeur) ;
            EXECUTE l ;
            RAISE NOTICE '> %', l ;
        END IF ;        
    END IF ;
    
    ------ RECREATION DES PRIVILEGES DU LECTEUR ------
    IF roles.lecteur IS NOT NULL
    THEN
        -- sur les tables :
        IF obj_typ IN ('table', 'view', 'materialized view', 'foreign table')
        THEN
            RAISE NOTICE 'application des privilèges standards pour le rôle lecteur du schéma :' ;
            l := format('GRANT SELECT ON TABLE %I.%I TO %I',
                obj_schema, obj_nom, roles.lecteur) ;
            EXECUTE l ;
            RAISE NOTICE '> %', l ;
        -- sur les séquences :
        ELSIF obj_typ IN ('sequence')
        THEN
            RAISE NOTICE 'application des privilèges standards pour le rôle lecteur du schéma :' ;
            l := format('GRANT SELECT ON SEQUENCE %I.%I TO %I',
                obj_schema, obj_nom, roles.lecteur) ;
            EXECUTE l ;
            RAISE NOTICE '> %', l ;
        END IF ;
    END IF ;

    EXECUTE format('SET ROLE %I', utilisateur) ;
                
    RETURN '__ REINITIALISATION REUSSIE.' ;

EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                            e_hint = PG_EXCEPTION_HINT,
                            e_detl = PG_EXCEPTION_DETAIL,
                            e_errcode = RETURNED_SQLSTATE,
                            e_schema = SCHEMA_NAME ;
    
    RAISE EXCEPTION '%', z_asgard.asgard_prefixe_erreur(e_mssg, 'FIO')
        USING DETAIL = e_detl,
            HINT = e_hint,
            SCHEMA = e_schema,
            ERRCODE = e_errcode ;
    
END
$_$ ;

ALTER FUNCTION z_asgard.asgard_initialise_obj(text, text, text)
    OWNER TO g_admin_ext ;

COMMENT ON FUNCTION z_asgard.asgard_initialise_obj(text, text, text) IS 'ASGARD. Réinitialise les privilèges sur un objet.' ;


------ 3.10 - DEPLACEMENT D'OBJET ------

-- Function: z_asgard.asgard_deplace_obj(text, text, text, text, int)

CREATE OR REPLACE FUNCTION z_asgard.asgard_deplace_obj(
    obj_schema text,
    obj_nom text,
    obj_typ text,
    schema_cible text,
    variante int DEFAULT 1
    )
    RETURNS text
    LANGUAGE plpgsql
    AS $_$
/* Déplace un objet vers un nouveau schéma, en transférant ou réinitialisant
   les privilèges selon la variante choisie.

    Lorsque des séquences sont associées aux champs de la table, la fonction
    gère également leurs privilèges.
   
    Parameters
    ----------
    obj_schema : text
        Le nom du schéma contenant l'objet.
    obj_nom : text
        Le nom de l'objet. À écrire sans les guillemets des identifiants
        PostgreSQL SAUF pour les fonctions, dont le nom doit impérativement
        être entre guillemets s'il ne respecte pas les conventions de
        nommage des identifiants PostgreSQL.
    obj_typ : {
        'table', 'partitioned table', 'view', 'materialized view', 
        'foreign table', 'sequence', 'function', 'aggregate', 'procedure', 
        'routine', 'type', 'domain'
    }
        Le type de l'objet. Pour les tables partitionnées, les types 'table'
        et 'partitioned table' sont acceptés.
    schema_cible : str
        Le nom du schéma où doit être déplacé l'objet.
    variante : int, default 1
        Un entier qui définit le comportement attendu par l'utilisateur
        vis-à-vis des privilèges :
        
        * 1 (valeur par défaut) | TRANSFERT COMPLET + CONSERVATION :
          les privilèges des rôles producteur, éditeur et lecteur de
          l'ancien schéma sont transférés sur ceux du nouveau. Si un
          éditeur ou lecteur a été désigné pour le nouveau schéma mais
          qu'aucun n'était défini pour l'ancien, le rôle reçoit les
          privilèges standards pour sa fonction. Le cas échéant,
          les privilèges des autres rôles sont conservés.
        * 2 | REINITIALISATION COMPLETE : les nouveaux
          producteur, éditeur et lecteur reçoivent les privilèges
          standard. Les privilèges des autres rôles sont supprimés.
        * 3 | TRANSFERT COMPLET + NETTOYAGE : les privilèges des rôles
          producteur, éditeur et lecteur de l'ancien schéma sont transférés
          sur ceux du nouveau. Si un éditeur ou lecteur a été désigné pour
          le nouveau schéma mais qu'aucun n'était défini pour l'ancien,
          le rôle reçoit les privilèges standards pour sa fonction.
          Les privilèges des autres rôles sont supprimés.
        * 4 | TRANSFERT PRODUCTEUR + CONSERVATION : les privilèges de
          l'ancien producteur sont transférés sur le nouveau. Les privilèges
          des autres rôles sont conservés tels quels. C'est le comportement
          d'une commande ALTER [...] SET SCHEMA (interceptée par le déclencheur
          sur évènement asgard_on_alter_objet).
        * 5 | TRANSFERT PRODUCTEUR + REINITIALISATION : les privilèges
          de l'ancien producteur sont transférés sur le nouveau. Les
          nouveaux éditeur et lecteur reçoivent les privilèges standards.
          Les privilèges des autres rôles sont supprimés.
        * 6 | REINITIALISATION PARTIELLE : les nouveaux
          producteur, éditeur et lecteur reçoivent les privilèges
          standard. Les privilèges des autres rôles sont conservés.
    
    Returns
    -------
    text
        '__ DEPLACEMENT REUSSI.' si la requête s'est exécutée normalement.

    Raises
    ------
    invalid_parameter_value
        FDO1. Si le schéma est considéré par Asgard comme un schéma système.
        FDO2. Si le schéma de l'objet (obj_schema) n'est pas référencé.
        FDO3. Si le schéma cible schema_cible n'est pas référencé.
        FDO4. Si le type obj_typ n'est pas reconnu.
        FDO5. S'il n'existe pas d'objet obj_nom dans le schéma obj_schema.
        FDO12. Si le schéma de l'objet (obj_schema) est référencé, mais pas
        en tant que schéma actif.
        FDO13. Si le schéma cible schema_cible est référencé, mais pas
        en tant que schéma actif.
    duplicate_object
        FDO8. S'il existe déjà un objet de même nom dans le schéma cible.
        FDO9 et FDO10. S'il existe déjà dans le schéma cible une relation de même
        nom que l'un des index associés à l'objet.
        FDO11. S'il existe déjà dans le schéma cible une relation de même
        nom que l'une des séquences associées à l'objet.

    Version notes
    -------------
    v1.5.0
        (M) Recours à asgard_cherche_executant pour trouver des 
            rôles habilités à exécuter les commandes.
            Le contrôle des permissions de l'utilisateur est dorénavant 
            entièrement délégué à cette fonction.
        (m) Recours à asgard_est_actif pour déterminer si les schémas
            de départ et d'arrivée sont référencés et actifs. Des erreurs 
            distinctes sont désormais renvoyées si le schéma n'est pas référencé
            (FDO2 et FDO3) ou n'est pas actif (FD012 et FDO13).
        (m) Recours à asgard_information pour récupérer les rôles
            producteur, éditeur et lecteur des schémas.
        (m) Recours à la fonction asgard_est_schema_systeme pour connaître
            les schémas système à exclure, au lieu d'une liste en dur.
        (m) Amélioration de la gestion des messages d'erreur.

*/
DECLARE
    class_info record ;
    roles record ;
    roles_cible record ;
    obj record ;
    r record ;
    c record ;
    l text ;
    c_lecteur text[] ;
    c_editeur text[] ;
    c_producteur text[] ;
    c_n_lecteur text[] ;
    c_n_editeur text[] ;
    c_autres text[] ;
    seq_liste oid[] ;
    a text[] ;
    s record ;
    o oid ;
    supported boolean ;
    duplicate oid ;
    e_mssg text ;
    e_detl text ;
    e_hint text ;
    e_schema text ;
    e_errcode text ;
    executant text ;
    utilisateur text := current_user ;
    actif boolean ;
BEGIN

    obj_typ := lower(obj_typ) ;

    -- pour la suite, on assimile les partitions à des tables
    IF obj_typ = 'partitioned table'
    THEN
        obj_typ := 'table' ;
    ELSIF obj_typ = ANY (ARRAY['routine', 'procedure', 'function', 'aggregate'])
    THEN
        -- à partir de PG 11, les fonctions et procédures sont des routines
        IF current_setting('server_version_num')::int >= 110000
        THEN
            obj_typ := 'routine' ;
        -- pour les versions antérieures, les routines et procédures n'existent
        -- théoriquement pas, mais on considère que ces mots-clés désignent
        -- des fonctions
        ELSE
            obj_typ := 'function' ;
        END IF ;
    END IF ;

    ------ TESTS PREALABLES ------
    -- schéma système
    IF z_asgard.asgard_est_schema_systeme(obj_schema)
    THEN
        RAISE EXCEPTION 'FDO1. Opération interdite. Le schéma % est un schéma système.', obj_schema
            USING ERRCODE = 'invalid_parameter_value',
                SCHEMA = obj_schema ;
    END IF ;
    
    -- schéma de départ non référencé
    actif := z_asgard.asgard_est_actif(obj_schema) ;

    IF actif IS NULL
    THEN
        RAISE EXCEPTION 'FDO2. Echec. Le schéma % n''est pas référencé dans la table de gestion d''Asgard.', obj_schema 
            USING ERRCODE = 'invalid_parameter_value',
                SCHEMA = obj_schema ;
    ELSIF NOT actif
    THEN
        RAISE EXCEPTION 'FDO12. Echec. Le schéma % n''est pas référencé en tant que schéma actif dans la table de gestion d''Asgard.', obj_schema
            USING ERRCODE = 'invalid_parameter_value',
                SCHEMA = obj_schema ;
    END IF ;
    
    -- schéma cible non référencé
    actif := z_asgard.asgard_est_actif(schema_cible) ;

    IF actif IS NULL
    THEN
        RAISE EXCEPTION 'FDO3. Echec. Le schéma cible % n''est pas référencé dans la table de gestion d''Asgard.', schema_cible 
            USING ERRCODE = 'invalid_parameter_value',
                SCHEMA = schema_cible ;
    ELSIF NOT actif
    THEN
        RAISE EXCEPTION 'FDO13. Echec. Le schéma cible % n''est pas référencé en tant que schéma actif dans la table de gestion d''Asgard.', schema_cible
            USING ERRCODE = 'invalid_parameter_value',
                SCHEMA = schema_cible ;
    END IF ;
    
    -- type invalide + récupération des informations sur le catalogue contenant l'objet
    SELECT
        xtyp, xclass, xreg,
        format('%sname', xprefix) AS xname,
        format('%sowner', xprefix) AS xowner,
        format('%snamespace', xprefix) AS xschema
        INTO class_info
        FROM unnest(
                ARRAY['table', 'foreign table', 'view', 'materialized view',
                    'sequence', 'type', 'domain', 'function', 'routine'],
                ARRAY['pg_class', 'pg_class', 'pg_class', 'pg_class',
                    'pg_class', 'pg_type', 'pg_type', 'pg_proc', 'pg_proc'],
                ARRAY['rel', 'rel', 'rel', 'rel', 'rel', 'typ', 'typ',
                    'pro', 'pro'],
                ARRAY['regclass', 'regclass', 'regclass', 'regclass', 'regclass',
                    'regtype', 'regtype', 'regprocedure', 'regprocedure']
                ) AS typ (xtyp, xclass, xprefix, xreg)
            WHERE typ.xtyp = obj_typ ;
            
    IF NOT FOUND
    THEN
        RAISE EXCEPTION 'FDO4. Echec. Le type % n''existe pas ou n''est pas pris en charge.', obj_typ
            USING HINT = 'Types acceptés : ''table'', ''partitioned table'', ''view'', ''materialized view'', ''foreign table'', ''sequence'', ''function'', ''aggregate'', ''procedure'', ''routine'', ''type'', ''domain''.',
                ERRCODE = 'invalid_parameter_value' ;
    END IF ;
    
    -- objet inexistant + récupération du propriétaire
    EXECUTE 'SELECT pg_roles.rolname, '
            || class_info.xclass || '.oid, '
            || CASE WHEN class_info.xclass = 'pg_type'
                    THEN quote_literal(quote_ident(obj_schema) || '.' || quote_ident(obj_nom)) || '::text'
                ELSE class_info.xclass || '.oid::' || class_info.xreg || '::text'
                END || ' AS appel,'
            || class_info.xname || ' AS objname'
            || CASE WHEN class_info.xclass = 'pg_proc'
                THEN ', pg_catalog.oidvectortypes(proargtypes) AS proargtypes' ELSE '' END
            || ' FROM pg_catalog.' || class_info.xclass
            || '     INNER JOIN pg_catalog.pg_roles ON pg_roles.oid = ' || class_info.xowner
            || ' WHERE ' || CASE WHEN class_info.xclass = 'pg_proc'
                    THEN class_info.xclass || '.oid = '
                        || quote_literal(quote_ident(obj_schema) || '.' || obj_nom)
                        || '::regprocedure'
                ELSE class_info.xname || ' = ' || quote_literal(obj_nom)
                    || ' AND ' || class_info.xschema || '::regnamespace::text = '
                    || quote_literal(quote_ident(obj_schema)) END
        INTO obj ;
    
    IF obj.rolname IS NULL
    THEN
        RAISE EXCEPTION 'FDO5. Echec. L''objet % n''existe pas.', obj_nom
            USING ERRCODE = 'invalid_parameter_value' ;
    END IF ;
    
    -- il existe déjà un objet de même définition dans le schéma cible
    IF class_info.xclass = 'pg_proc' THEN
        EXECUTE format('
            SELECT oid FROM pg_catalog.pg_proc
                WHERE pronamespace = %L::regnamespace
                    AND proname = %L
                    AND pg_catalog.oidvectortypes(proargtypes) = %L',
            quote_ident(schema_cible), obj.objname, obj.proargtypes)
            INTO duplicate ;
    ELSE
        EXECUTE format('
            SELECT oid FROM pg_catalog.%s
                WHERE %s = %L::regnamespace
                    AND %s = %L',
            class_info.xclass,
            class_info.xschema, quote_ident(schema_cible),
            class_info.xname, obj.objname)
            INTO duplicate ;
    END IF ;
        
    IF duplicate IS NOT NULL
    THEN
        RAISE EXCEPTION 'FDO8. Opération interdite. Il existe déjà un objet de même définition dans le schéma cible.'
            USING ERRCODE = 'duplicate_object',
                SCHEMA = schema_cible ;
    END IF ;
    
    ------ RECUPERATION DES ROLES ------
    -- schéma de départ :
    SELECT info.producteur, info.editeur, info.lecteur INTO roles
        FROM z_asgard.asgard_information(
            obj_schema,
            consolide_roles := True
        ) AS info ;
        
    -- schéma cible :
    SELECT info.producteur, info.editeur, info.lecteur INTO roles_cible
        FROM z_asgard.asgard_information(
            schema_cible,
            consolide_roles := True
        ) AS info ;
    
    ------ MEMORISATION DES PRIVILEGES ACTUELS ------
    -- ancien producteur :
    SELECT array_agg(commande) INTO c_producteur
        FROM z_asgard.asgard_synthese_role_obj(
                obj.oid, obj_typ, quote_ident(roles.producteur)::regrole) ;
    
    -- ancien éditeur :
    IF roles.editeur = 'public'
    THEN
        IF obj_typ IN ('table', 'view', 'materialized view', 'sequence',
                'foreign table', 'partitioned table')
        THEN
            SELECT array_agg(commande) INTO c_editeur
                FROM z_asgard.asgard_synthese_public_obj(obj.oid, obj_typ) ;
        END IF ;
    ELSIF roles.editeur IS NOT NULL
    THEN
        SELECT array_agg(commande) INTO c_editeur
            FROM z_asgard.asgard_synthese_role_obj(
                    obj.oid, obj_typ, quote_ident(roles.editeur)::regrole) ;
    END IF ;
                
    -- ancien lecteur :
    IF roles.lecteur = 'public'
    THEN
        IF obj_typ IN ('table', 'view', 'materialized view', 'sequence',
                'foreign table', 'partitioned table')
        THEN
            SELECT array_agg(commande) INTO c_lecteur
                FROM z_asgard.asgard_synthese_public_obj(obj.oid, obj_typ) ;
        END IF ;
    ELSIF roles.lecteur IS NOT NULL
    THEN
        SELECT array_agg(commande) INTO c_lecteur
            FROM z_asgard.asgard_synthese_role_obj(
                    obj.oid, obj_typ, quote_ident(roles.lecteur)::regrole) ;
    END IF ;
    
    -- nouvel éditeur :
    IF roles_cible.editeur = 'public'
    THEN
        IF obj_typ IN ('table', 'view', 'materialized view', 'sequence',
                'foreign table', 'partitioned table')
        THEN
            SELECT array_agg(commande) INTO c_n_editeur
                FROM z_asgard.asgard_synthese_public_obj(obj.oid, obj_typ) ;
        END IF ;
    ELSIF roles_cible.editeur IS NOT NULL
    THEN
        SELECT array_agg(commande) INTO c_n_editeur
            FROM z_asgard.asgard_synthese_role_obj(
                    obj.oid, obj_typ, quote_ident(roles_cible.editeur)::regrole) ;
    END IF ;
                
    -- nouveau lecteur :
    IF roles_cible.lecteur = 'public'
    THEN
        IF obj_typ IN ('table', 'view', 'materialized view', 'sequence',
                'foreign table', 'partitioned table')
        THEN
            SELECT array_agg(commande) INTO c_n_lecteur
                FROM z_asgard.asgard_synthese_public_obj(obj.oid, obj_typ) ;
        END IF ;
    ELSIF roles_cible.lecteur IS NOT NULL
    THEN
        SELECT array_agg(commande) INTO c_n_lecteur
            FROM z_asgard.asgard_synthese_role_obj(
                    obj.oid, obj_typ, quote_ident(roles_cible.lecteur)::regrole) ;
    END IF ;
    
    -- autres rôles :
    -- pour ces commandes, contrairement aux précédentes, le rôle
    -- est inséré dès maintenant (avec "format")
    -- public
    IF NOT 'public' = ANY (array_remove(ARRAY[roles.producteur, roles.lecteur, roles.editeur,
            roles_cible.producteur, roles_cible.lecteur, roles_cible.editeur], NULL))
    THEN
        IF obj_typ IN ('table', 'view', 'materialized view', 'sequence',
                'foreign table', 'partitioned table')
        THEN
            SELECT array_agg(format(commande, 'public')) INTO c_autres
                FROM z_asgard.asgard_synthese_public_obj(obj.oid, obj_typ) ;
        END IF ;
    END IF ;
    -- et le reste
    FOR r IN (SELECT rolname FROM pg_roles
            WHERE NOT rolname = ANY (array_remove(ARRAY[roles.producteur, roles.lecteur, roles.editeur,
                roles_cible.producteur, roles_cible.lecteur, roles_cible.editeur], NULL)))
    LOOP
        SELECT array_agg(format(commande, r.rolname::text)) INTO a
            FROM z_asgard.asgard_synthese_role_obj(
                    obj.oid, obj_typ, quote_ident(r.rolname)::regrole) ;
        IF FOUND
        THEN
            c_autres := array_cat(c_autres, a) ;
            a := NULL ;
        END IF ;
    END LOOP ;
    
    ------ BREF CONTRÔLE DES INDEX ------
    -- il s'agit seulement de vérifier qu'il n'existe pas déjà d'index
    -- de même nom dans le schéma cible
    
    -- 1. index qui dépendent d'une contrainte, tels les index
    -- des clés primaires
    FOR s IN (
        SELECT
            pg_class.oid,
            pg_class.relname
            FROM pg_catalog.pg_constraint
                LEFT JOIN pg_catalog.pg_class ON pg_class.oid = pg_constraint.conindid
            WHERE pg_constraint.conrelid = obj.oid 
                AND pg_constraint.conindid IS NOT NULL
        )
    LOOP
        IF EXISTS (SELECT oid FROM pg_catalog.pg_class
            WHERE pg_class.relname = s.relname
                AND relnamespace = quote_ident(schema_cible)::regnamespace)
        THEN
            RAISE EXCEPTION 'FDO9. Opération interdite. Il existe dans le schéma cible une relation de même nom que l''index associé %.', s.relname
                USING ERRCODE = 'duplicate_object' ;
        END IF ;
    END LOOP ;
    
    -- 2. autres index (qui dépendent directement de la table)
    FOR s IN (
        SELECT
            pg_class.oid,
            pg_class.relname
            FROM pg_catalog.pg_depend LEFT JOIN pg_catalog.pg_class
                ON pg_class.oid = pg_depend.objid
            WHERE pg_depend.classid = 'pg_catalog.pg_class'::regclass::oid
                AND pg_depend.refclassid = 'pg_catalog.pg_class'::regclass::oid
                AND pg_depend.refobjid = obj.oid
                AND pg_depend.refobjsubid > 0
                AND pg_depend.deptype = ANY (ARRAY['a', 'i'])
                AND pg_class.relkind = 'i'
        )
    LOOP
        IF EXISTS (SELECT oid FROM pg_catalog.pg_class
            WHERE pg_class.relname = s.relname
                AND relnamespace = quote_ident(schema_cible)::regnamespace)
        THEN
            RAISE EXCEPTION 'FDO10. Opération interdite. Il existe dans le schéma cible une relation de même nom que l''index associé %.', s.relname
                USING ERRCODE = 'duplicate_object' ;
        END IF ;
    END LOOP ;
    
    ------ PRIVILEGES SUR LES SEQUENCES ASSOCIEES ------
    IF obj_typ = 'table'
    THEN
        -- dans le cas d'une table, on recherche les séquences
        -- utilisées par ses éventuels champs de type serial ou
        -- IDENTITY
        -- elles sont repérées par le fait qu'il existe
        -- une dépendance entre la séquence et un champ de la table :
        -- de type DEPENDENCY_AUTO (a) pour la séquence d'un champ serial
        -- de type DEPENDENCY_INTERNAL (i) pour la séquence d'un champ IDENDITY
        FOR s IN (
            SELECT
                pg_class.oid,
                pg_class.relname
                FROM pg_catalog.pg_depend LEFT JOIN pg_catalog.pg_class
                    ON pg_class.oid = pg_depend.objid
                WHERE pg_depend.classid = 'pg_catalog.pg_class'::regclass::oid
                    AND pg_depend.refclassid = 'pg_catalog.pg_class'::regclass::oid
                    AND pg_depend.refobjid = obj.oid
                    AND pg_depend.refobjsubid > 0
                    AND pg_depend.deptype = ANY (ARRAY['a', 'i'])
                    AND pg_class.relkind = 'S'
            )
        LOOP
            -- il existe déjà une séquence de même nom dans le schéma cible
            IF EXISTS (SELECT oid FROM pg_catalog.pg_class
                WHERE pg_class.relname = s.relname
                    AND relnamespace = quote_ident(schema_cible)::regnamespace)
            THEN
                RAISE EXCEPTION 'FDO11. Opération interdite. Il existe dans le schéma cible une relation de même nom que la séquence associée %.', s.relname
                    USING ERRCODE = 'duplicate_object' ;
            END IF ;
        
            -- liste des séquences
            seq_liste := array_append(seq_liste, s.oid) ;
            
            -- récupération des privilèges
            -- ancien producteur :
            SELECT array_agg(commande) INTO a
                FROM z_asgard.asgard_synthese_role_obj(
                        s.oid, 'sequence', quote_ident(roles.producteur)::regrole) ;
            IF FOUND
            THEN
                c_producteur := array_cat(c_producteur, a) ;
                a := NULL ;
            END IF ;
        
            -- ancien éditeur :
            IF roles.editeur = 'public'
            THEN
                SELECT array_agg(commande) INTO a
                    FROM z_asgard.asgard_synthese_public_obj(s.oid, 'sequence'::text) ;
            ELSIF roles.editeur IS NOT NULL
            THEN
                SELECT array_agg(commande) INTO a
                    FROM z_asgard.asgard_synthese_role_obj(
                            s.oid, 'sequence'::text, quote_ident(roles.editeur)::regrole) ;
            END IF ;
            IF a IS NOT NULL
            THEN
                c_editeur := array_cat(c_editeur, a) ;
                a := NULL ;
            END IF ;
                        
            -- ancien lecteur :
            IF roles.lecteur = 'public'
            THEN
                SELECT array_agg(commande) INTO a
                    FROM z_asgard.asgard_synthese_public_obj(s.oid, 'sequence'::text) ;
            ELSIF roles.lecteur IS NOT NULL
            THEN
                SELECT array_agg(commande) INTO a
                    FROM z_asgard.asgard_synthese_role_obj(
                            s.oid, 'sequence'::text, quote_ident(roles.lecteur)::regrole) ;
            END IF ;
            IF a IS NOT NULL
            THEN
                c_lecteur := array_cat(c_lecteur, a) ;
                a := NULL ;
            END IF ;
            
            -- nouvel éditeur :
            IF roles_cible.editeur = 'public'
            THEN
                SELECT array_agg(commande) INTO a
                    FROM z_asgard.asgard_synthese_public_obj(s.oid, 'sequence'::text) ;
            ELSIF roles_cible.editeur IS NOT NULL
            THEN
                SELECT array_agg(commande) INTO a
                    FROM z_asgard.asgard_synthese_role_obj(
                            s.oid, 'sequence'::text, quote_ident(roles_cible.editeur)::regrole) ;
            END IF ;
            IF a IS NOT NULL
            THEN
                c_n_editeur := array_cat(c_n_editeur, a) ;
                a := NULL ;
            END IF ;
                        
            -- nouveau lecteur :
            IF roles_cible.lecteur = 'public'
            THEN
                SELECT array_agg(commande) INTO a
                    FROM z_asgard.asgard_synthese_public_obj(s.oid, 'sequence'::text) ;
            ELSIF roles_cible.lecteur IS NOT NULL
            THEN
                SELECT array_agg(commande) INTO a
                    FROM z_asgard.asgard_synthese_role_obj(
                            s.oid, 'sequence'::text, quote_ident(roles_cible.lecteur)::regrole) ;
            END IF ;
            IF a IS NOT NULL
            THEN
                c_n_lecteur := array_cat(c_n_lecteur, a) ;
                a := NULL ;
            END IF ;
            
            -- autres rôles :
            -- public
            IF NOT 'public' = ANY (array_remove(ARRAY[roles.producteur, roles.lecteur, roles.editeur,
                    roles_cible.producteur, roles_cible.lecteur, roles_cible.editeur], NULL))
            THEN
                SELECT array_agg(format(commande, 'public')) INTO a
                    FROM z_asgard.asgard_synthese_public_obj(s.oid, 'sequence'::text) ;
                IF FOUND
                THEN
                    c_autres := array_cat(c_autres, a) ;
                    a := NULL ;
                END IF ;
            END IF ;
            -- et le reste
            FOR r IN (SELECT rolname FROM pg_roles
                    WHERE NOT rolname = ANY (array_remove(ARRAY[roles.producteur, roles.lecteur, roles.editeur,
                        roles_cible.producteur, roles_cible.lecteur, roles_cible.editeur], NULL)))
            LOOP
                SELECT array_agg(format(commande, r.rolname::text)) INTO a
                    FROM z_asgard.asgard_synthese_role_obj(
                            s.oid, 'sequence'::text, quote_ident(r.rolname)::regrole) ;
                IF FOUND
                THEN
                    c_autres := array_cat(c_autres, a) ;
                    a := NULL ;
                END IF ;
            END LOOP ;
        END LOOP ;
    END IF ;
    
    ------ DEPLACEMENT DE L'OBJET ------
    -- choix d'un rôle habilité à exécuter les commandes (sinon
    -- asgard_cherche_executant émet une erreur)
    executant := z_asgard.asgard_cherche_executant(
            'ALTER OBJECT SCHEMA', 
            new_producteur := roles.producteur,
            old_producteur := obj.rolname
        ) ;
    EXECUTE format('SET ROLE %I', executant) ;

    EXECUTE format('ALTER %s %s SET SCHEMA %I', obj_typ, obj.appel, schema_cible) ;
    RAISE NOTICE '... Objet déplacé dans le schéma %.', schema_cible ;

    EXECUTE format('SET ROLE %I', utilisateur) ;
  
    ------ PRIVILEGES DU PRODUCTEUR ------
    -- par défaut, ils ont été transférés
    -- lors du changement de propriétaire, il
    -- n'y a donc qu'à réinitialiser pour les
    -- variantes 2 et 6

    -- choix d'un rôle habilité à exécuter les commandes (sinon
    -- asgard_cherche_executant émet une erreur)
    executant := z_asgard.asgard_cherche_executant(
        'PRIVILEGES', 
        new_producteur := roles.producteur
    ) ;
    EXECUTE format('SET ROLE %I', executant) ;
    
    -- objet, réinitialisation pour 2 et 6
    IF variante IN (2, 6) AND (c_producteur IS NOT NULL)
    THEN
        RAISE NOTICE 'réinitialisation des privilèges du nouveau producteur, % :', roles_cible.producteur ;
        FOREACH l IN ARRAY c_producteur
        LOOP
            l := z_asgard.asgard_grant_to_revoke(replace(l, format('%I.', obj_schema), format('%I.', schema_cible))) ;
            EXECUTE format(l, roles_cible.producteur) ;
            RAISE NOTICE '> %', format(l, roles_cible.producteur) ;
        END LOOP ;
    END IF ;
    
    ------- PRIVILEGES EDITEUR ------
    -- révocation des privilèges du nouvel éditeur
    IF roles_cible.editeur IS NOT NULL
            AND (roles.editeur IS NULL OR NOT roles.editeur = roles_cible.editeur)
            AND NOT roles.producteur = roles_cible.editeur
            AND NOT variante = 4
            AND c_n_editeur IS NOT NULL
    THEN
        RAISE NOTICE 'suppression des privilèges pré-existants du nouvel éditeur, % :', roles_cible.editeur ;
        FOREACH l IN ARRAY c_n_editeur
        LOOP
            l := z_asgard.asgard_grant_to_revoke(replace(l, format('%I.', obj_schema), format('%I.', schema_cible))) ;
            EXECUTE format(l, roles_cible.editeur) ;
            RAISE NOTICE '> %', format(l, roles_cible.editeur) ;  
        END LOOP ;
    END IF ;
    
    -- révocation des privilèges de l'ancien éditeur
    IF roles.editeur IS NOT NULL AND NOT roles.editeur = roles_cible.producteur
            AND (roles_cible.editeur IS NULL OR NOT roles.editeur = roles_cible.editeur OR NOT variante IN (1,3))
            AND NOT variante = 4
            AND c_editeur IS NOT NULL
    THEN
        RAISE NOTICE 'suppression des privilèges de l''ancien éditeur, % :', roles.editeur ;
        FOREACH l IN ARRAY c_editeur
        LOOP
            l := z_asgard.asgard_grant_to_revoke(replace(l, format('%I.', obj_schema), format('%I.', schema_cible))) ;
            EXECUTE format(l, roles.editeur) ;
            RAISE NOTICE '> %', format(l, roles.editeur) ;  
        END LOOP ;
    END IF ;
    
    -- reproduction sur le nouvel éditeur pour les variantes 1 et 3
    IF roles.editeur IS NOT NULL
            AND roles_cible.editeur IS NOT NULL
            AND variante IN (1, 3)
            AND c_editeur IS NOT NULL
            AND NOT roles.editeur = roles_cible.editeur
    THEN
        RAISE NOTICE 'transfert des privilèges de l''ancien éditeur vers le nouvel éditeur, % :', roles_cible.editeur ;
        FOREACH l IN ARRAY c_editeur
        LOOP
            l := replace(l, format('%I.', obj_schema), format('%I.', schema_cible)) ;
            EXECUTE format(l, roles_cible.editeur) ;
            RAISE NOTICE '> %', format(l, roles_cible.editeur) ;  
        END LOOP ;
    END IF ;
    
    -- attribution des privilèges standard au nouvel éditeur
    -- pour les variantes 2, 5, 6
    -- ou s'il n'y avait pas de lecteur sur l'ancien schéma
    IF roles_cible.editeur IS NOT NULL
          AND (variante IN (2, 5, 6) OR roles.editeur IS NULL)
          AND NOT variante = 4
    THEN
        -- sur les tables :
        IF obj_typ IN ('table', 'view', 'materialized view', 'foreign table')
        THEN
            RAISE NOTICE 'application des privilèges standards pour le rôle éditeur du schéma :' ;
            l := format('GRANT SELECT, UPDATE, DELETE, INSERT ON TABLE %I.%I TO %I',
                schema_cible, obj_nom, roles_cible.editeur) ;
            EXECUTE l ;
            RAISE NOTICE '> %', l ;
        -- sur les séquences libres :
        ELSIF obj_typ IN ('sequence')
        THEN
            RAISE NOTICE 'application des privilèges standards pour le rôle éditeur du schéma :' ;
            l := format('GRANT SELECT, USAGE ON SEQUENCE %I.%I TO %I',
                schema_cible, obj_nom, roles_cible.editeur) ;
            EXECUTE l ;
            RAISE NOTICE '> %', l ;
        END IF ;
        -- sur les séquences des champs serial :
        IF seq_liste IS NOT NULL
        THEN
            FOREACH o IN ARRAY seq_liste
            LOOP
                l := format('GRANT SELECT, USAGE ON SEQUENCE %s TO %I',
                    o::regclass, roles_cible.editeur) ;
                EXECUTE l ;
                RAISE NOTICE '> %', l ;
            END LOOP ;
        END IF ;
    END IF ;
    
    ------- PRIVILEGES LECTEUR ------
    -- révocation des privilèges du nouveau lecteur
    IF roles_cible.lecteur IS NOT NULL
            AND (roles.lecteur IS NULL OR NOT roles.lecteur = roles_cible.lecteur)
            AND NOT roles.producteur = roles_cible.lecteur
            AND (roles.editeur IS NULL OR NOT roles.editeur = roles_cible.lecteur)
            AND NOT variante = 4
            AND c_n_lecteur IS NOT NULL
    THEN
        RAISE NOTICE 'suppression des privilèges pré-existants du nouveau lecteur, % :', roles_cible.lecteur ;
        FOREACH l IN ARRAY c_n_lecteur
        LOOP
            l := z_asgard.asgard_grant_to_revoke(replace(l, format('%I.', obj_schema), format('%I.', schema_cible))) ;
            EXECUTE format(l, roles_cible.lecteur) ;
            RAISE NOTICE '> %', format(l, roles_cible.lecteur) ;  
        END LOOP ;
    END IF ;
    
    -- révocation des privilèges de l'ancien lecteur
    IF roles.lecteur IS NOT NULL AND NOT roles.lecteur = roles_cible.producteur
           AND (roles_cible.editeur IS NULL OR NOT roles.lecteur = roles_cible.editeur)
           AND (roles_cible.lecteur IS NULL OR NOT roles.lecteur = roles_cible.lecteur OR NOT variante IN (1,3))
           AND NOT variante = 4
           AND c_lecteur IS NOT NULL
    THEN
        RAISE NOTICE 'suppression des privilèges de l''ancien lecteur, % :', roles.lecteur ;
        FOREACH l IN ARRAY c_lecteur
        LOOP
            l := z_asgard.asgard_grant_to_revoke(replace(l, format('%I.', obj_schema), format('%I.', schema_cible))) ;
            EXECUTE format(l, roles.lecteur) ;
            RAISE NOTICE '> %', format(l, roles.lecteur) ;  
        END LOOP ;
    END IF ;
    
    -- reproduction sur le nouveau lecteur pour les variantes 1 et 3
    IF roles.lecteur IS NOT NULL
            AND roles_cible.lecteur IS NOT NULL
            AND variante IN (1, 3)
            AND c_lecteur IS NOT NULL
            AND NOT roles.lecteur = roles_cible.lecteur
    THEN
        RAISE NOTICE 'transfert des privilèges de l''ancien lecteur vers le nouveau lecteur, % :', roles_cible.lecteur ;
        FOREACH l IN ARRAY c_lecteur
        LOOP
            l := replace(l, format('%I.', obj_schema), format('%I.', schema_cible)) ;
            EXECUTE format(l, roles_cible.lecteur) ;
            RAISE NOTICE '> %', format(l, roles_cible.lecteur) ;  
        END LOOP ;
    END IF ;
    
    -- attribution des privilèges standard au nouveau lecteur
    -- pour les variantes 2, 5, 6
    -- ou s'il n'y avait pas de lecteur sur l'ancien schéma
    IF roles_cible.lecteur IS NOT NULL
          AND (variante IN (2, 5, 6) OR roles.lecteur IS NULL)
          AND NOT variante = 4
    THEN
        -- sur les tables :
        IF obj_typ IN ('table', 'view', 'materialized view', 'foreign table')
        THEN
            RAISE NOTICE 'application des privilèges standards pour le rôle lecteur du schéma :' ;
            l := format('GRANT SELECT ON TABLE %I.%I TO %I',
                schema_cible, obj_nom, roles_cible.lecteur) ;
            EXECUTE l ;
            RAISE NOTICE '> %', l ;
        -- sur les séquences libres :
        ELSIF obj_typ IN ('sequence')
        THEN
            RAISE NOTICE 'application des privilèges standards pour le rôle lecteur du schéma :' ;
            l := format('GRANT SELECT ON SEQUENCE %I.%I TO %I',
                schema_cible, obj_nom, roles_cible.lecteur) ;
            EXECUTE l ;
            RAISE NOTICE '> %', l ;
        END IF ; 
        -- sur les séquences des champs serial :
        IF seq_liste IS NOT NULL
        THEN
            FOREACH o IN ARRAY seq_liste
            LOOP
                l := format('GRANT SELECT ON SEQUENCE %s TO %I', o::regclass, roles_cible.lecteur) ;
                EXECUTE l ;
                RAISE NOTICE '> %', l ;
            END LOOP ;
        END IF ;
    END IF ;
    
    ------ AUTRES ROLES ------
    -- pour les variantes 2, 3, 5, remise à zéro
    IF variante IN (2, 3, 5)
        AND c_autres IS NOT NULL
    THEN
        RAISE NOTICE 'remise à zéro des privilèges des autres rôles :' ;
        FOREACH l IN ARRAY c_autres
        LOOP
            l := z_asgard.asgard_grant_to_revoke(replace(l, format('%I.', obj_schema), format('%I.', schema_cible))) ;
            EXECUTE l ;
            RAISE NOTICE '> %', l ;  
        END LOOP ;    
    END IF ;

    EXECUTE format('SET ROLE %I', utilisateur) ;

    RETURN '__ DEPLACEMENT REUSSI.' ;

EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                            e_hint = PG_EXCEPTION_HINT,
                            e_detl = PG_EXCEPTION_DETAIL,
                            e_errcode = RETURNED_SQLSTATE,
                            e_schema = SCHEMA_NAME ;
    
    RAISE EXCEPTION '%', z_asgard.asgard_prefixe_erreur(e_mssg, 'FDO')
        USING DETAIL = e_detl,
            HINT = e_hint,
            SCHEMA = e_schema,
            ERRCODE = e_errcode ;

END
$_$ ;

ALTER FUNCTION z_asgard.asgard_deplace_obj(text, text, text, text, int)
    OWNER TO g_admin_ext ;

COMMENT ON FUNCTION z_asgard.asgard_deplace_obj(text, text, text, text, int) IS 'ASGARD. Déplace un objet vers un nouveau schéma, en transférant ou réinitialisant les privilèges selon la variante choisie.' ;


------ 3.11 - OCTROI MASSIF DE PERMISSIONS SUR LES RÔLES ------

-- Function: z_asgard_admin.asgard_all_login_grant_role(text, boolean)

CREATE OR REPLACE FUNCTION z_asgard_admin.asgard_all_login_grant_role(
    n_role text, 
    b boolean DEFAULT True
)
    RETURNS int
    LANGUAGE plpgsql
    AS $_$
/* Confère à tous les rôles de connexion du serveur l'appartenance au rôle
   donné en argument.

    Parameters
    ----------
    n_role : text
        Une chaîne de caractères présumée correspondre à un nom de
        rôle valide.
    b : boolean, default True
        Si b vaut False et qu'un rôle de connexion est déjà membre
        du rôle considéré par héritage, la fonction ne fait rien. Si
        b vaut True (défaut), la fonction ne passera un rôle de connexion
        que s'il est lui-même membre du rôle considéré.
        
    Returns
    -------
    int
        Le nombre de rôles pour lesquels la permission a été accordée.

    Version notes
    -------------
    v1.5.0
        (M) Recours à asgard_cherche_executant pour trouver un 
            rôle habilité à conférer des permissions sur le rôle cible.
            Le contrôle des permissions de l'utilisateur est dorénavant 
            entièrement délégué à cette fonction.
        (m) Amélioration de la gestion des messages d'erreur.
        (m) Correction du comportement de la fonction lorsqu'elle est
            appliquée à des rôles dont le nom n'est pas normalisé.
    
*/
DECLARE
    roles record ;
    executant text ;
    utilisateur text := current_user ;
    c text ;
    n int := 0 ;
    e_mssg text ;
    e_detl text ;
    e_hint text ;
    e_schema text ;
    e_errcode text ;
BEGIN

    -- choix d'un rôle habilité à exécuter les commandes (sinon
    -- asgard_cherche_executant émet une erreur)
    executant := z_asgard.asgard_cherche_executant(
        'GRANT ROLE',
        new_producteur := n_role
    ) ;
    EXECUTE format('SET ROLE %I', executant) ;
    
    IF b
    THEN
        FOR roles IN (
            SELECT 
                pg_roles.rolname
                FROM pg_catalog.pg_roles 
                    LEFT JOIN pg_catalog.pg_auth_members
                        ON pg_auth_members.member = pg_roles.oid 
                            AND pg_auth_members.roleid = quote_ident(n_role)::regrole
                WHERE pg_roles.rolcanlogin 
                    AND pg_auth_members.member IS NULL
                    AND NOT pg_roles.rolsuper
        )
        LOOP
            c := format('GRANT %I TO %I', n_role, roles.rolname) ;
            EXECUTE c ;
            RAISE NOTICE '> %', c ;
            n := n + 1 ;
        END LOOP ;
    ELSE
        FOR roles IN (
            SELECT 
                pg_roles.rolname 
                FROM pg_catalog.pg_roles
                WHERE pg_roles.rolcanlogin 
                    AND NOT pg_has_role(pg_roles.rolname, n_role, 'MEMBER')
        )
        LOOP
            c := format('GRANT %I TO %I', n_role, roles.rolname) ;
            EXECUTE c ;
            RAISE NOTICE '> %', c ;
            n := n + 1 ;
        END LOOP ;
    END IF ;
    
    EXECUTE format('SET ROLE %I', utilisateur) ;
    
    RETURN n ;

EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                            e_hint = PG_EXCEPTION_HINT,
                            e_detl = PG_EXCEPTION_DETAIL,
                            e_errcode = RETURNED_SQLSTATE,
                            e_schema = SCHEMA_NAME ;
    
    RAISE EXCEPTION '%', z_asgard.asgard_prefixe_erreur(e_mssg, 'FLG')
        USING DETAIL = e_detl,
            HINT = e_hint,
            SCHEMA = e_schema,
            ERRCODE = e_errcode ;

END
$_$ ;

ALTER FUNCTION z_asgard_admin.asgard_all_login_grant_role(text, boolean)
    OWNER TO g_admin ;

COMMENT ON FUNCTION z_asgard_admin.asgard_all_login_grant_role(text, boolean) IS 'ASGARD. Confère à tous les rôles de connexion du serveur l''appartenance au rôle donné en argument.' ;


------ 3.12 - IMPORT DE LA NOMENCLATURE DANS GESTION_SCHEMA ------

-- Function: z_asgard_admin.asgard_import_nomenclature(text[])

CREATE OR REPLACE FUNCTION z_asgard_admin.asgard_import_nomenclature(
    domaines text[] default NULL::text[]
)
    RETURNS text
    LANGUAGE plpgsql
    AS $_$
/* Importe dans la table de gestion les schémas manquants de la nomenclature nationale
   - ou de certains domaines de la nomenclature nationale listés en argument.
   
    Les schémas sont toujours importés en tant que schémas inactifs (champ 
    "creation" valant False), même si le schéma existe sans avoir été référencé
    dans la table de gestion.

    Des messages informent l'opérateur des schémas effectivement ajoutés.

    Lorsque le schéma est déjà référencé dans la table de gestion, réappliquer
    la fonction a pour effet de mettre à jour les champs relatifs à la
    nomenclature. Il est prévu qu'elle soit utilisée à cette fin.

    Parameters
    ----------
    domaines : text[], optional
        Une liste des noms des domaines à importer, soit le "niveau 1"/niv1 
        ou niv1_abr des schémas. Si non renseigné, toute la nomenclature 
        est importée (hors schémas déjà référencés).

    Returns
    -------
    text
        '__ FIN IMPORT NOMENCLATURE.' si la requête s'est exécutée normalement.

    Raises
    ------
    insufficient_privilege
        FIN1. Si le rôle qui exécute la fonction n'hérite pas des droits
        de g_admin.

    Version notes
    -------------
    v1.5.0
        (m) Ajout d'un contrôle vérifiant que le rôle qui exécute la
            fonction hérite des privilèges de g_admin.
        (m) Amélioration de la gestion des messages d'erreur.
        (d) Enrichissement du descriptif.

*/
DECLARE
    item record ;
    e_mssg text ;
    e_hint text ;
    e_detl text ;
    e_schema text ;
    e_errcode text ;
BEGIN

    ------ CONTROLES PREALABLES ------
    -- la fonction est dans z_asgard_admin, donc seuls les membres de
    -- g_admin devraient pouvoir y accéder, mais au cas où :
    IF NOT pg_has_role('g_admin', 'USAGE')
    THEN
        RAISE EXCEPTION 'FIN1. Opération interdite. Vous devez être membre de g_admin pour exécuter cette fonction.'
            USING ERRCODE = 'insufficient_privilege' ;
    END IF ;

    ------ IMPORT DES DONNEES ------
    FOR item IN SELECT * FROM (
            VALUES
                ('c', true, 'Données génériques', 'donnee_generique', 'Découpage électoral', 'decoupage_electoral', 'c_don_gen_decoupage_electoral', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Données génériques', 'donnee_generique', 'Démographie', 'demographie', 'c_don_gen_demographie', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Données génériques', 'donnee_generique', 'Habillage des cartes', 'habillage', 'c_don_gen_habillage', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Données génériques', 'donnee_generique', 'Intercommunalité', 'intercommunalite', 'c_don_gen_intercommunalite', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Données génériques', 'donnee_generique', 'Milieu physique', 'milieu_physique', 'c_don_gen_milieu_physique', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Eau', 'eau', 'Alimentation en eau potable', 'aep', 'c_eau_aep', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Eau', 'eau', 'Assainissement', 'assainissement', 'c_eau_assainissement', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Eau', 'eau', 'Masses d’eau', 'masse_eau', 'c_eau_masse_eau', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Eau', 'eau', 'Ouvrages', 'ouvrage', 'c_eau_ouvrage', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Eau', 'eau', 'Pêche', 'peche', 'c_eau_peche', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Eau', 'eau', 'Surveillance', 'surveillance', 'c_eau_surveillance', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Agriculture', 'agriculture', 'Environnement', 'agri_environnement', 'c_agri_environnement', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Agriculture', 'agriculture', 'Agro-alimentaire', 'agro_alimentaire', 'c_agri_agroalimentaire', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Agriculture', 'agriculture', 'Exploitation & élevage', 'exploitation_elevage', 'c_agri_exploi_elevage', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Agriculture', 'agriculture', 'Parcellaire agricole', 'parcellaire_agricole', 'c_agri_parcellaire_agricole', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Agriculture', 'agriculture', 'Santé animale', 'sante_animale', 'c_agri_sante_animale', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Agriculture', 'agriculture', 'Santé végétale', 'sante_vegetale', 'c_agri_sante_vegetale', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Risques', 'risque', 'Séismes', 'seisme', 'c_risque_seisme', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Agriculture', 'agriculture', 'Zonages agricoles', 'zonages_agricoles', 'c_agri_zonages_agricoles', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Air & climat', 'air_climat', 'Changement climatique', 'changement_climatique', 'c_air_clim_changement', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Air & climat', 'air_climat', 'Météorologie', 'meteo', 'c_air_clim_meteo', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Air & climat', 'air_climat', 'Qualité de l’air & pollution', 'qualite_pollution', 'c_air_clim_qual_pollu', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Aménagement & urbanisme', 'amenagement_urbanisme', 'Assiettes des servitudes', 'assiette_servitude', 'c_amgt_urb_servitude', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Aménagement & urbanisme', 'amenagement_urbanisme', 'Politique européenne', 'politique_europeenne', 'c_amgt_urb_pol_euro', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Aménagement & urbanisme', 'amenagement_urbanisme', 'Zonages d’aménagement', 'zonages_amenagement', 'c_amgt_urb_zon_amgt', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Aménagement & urbanisme', 'amenagement_urbanisme', 'Zonages d’études', 'zonages_etudes', 'c_amgt_urb_zon_etudes', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Aménagement & urbanisme', 'amenagement_urbanisme', 'Zonages de planification', 'zonages_planification', 'c_amgt_urb_zon_plan', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Culture, société & services', 'culture_societe_service', 'Enseignement', 'enseignement', 'c_cult_soc_ser_enseignement', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Culture, société & services', 'culture_societe_service', 'Équipements sportifs et culturels', 'equipement_sportif_culturel', 'c_cult_soc_ser_equip_sport_cult', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Culture, société & services', 'culture_societe_service', 'Autres établissements', 'erp_autre', 'c_cult_soc_ser_erp_autre', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Culture, société & services', 'culture_societe_service', 'Patrimoine culturel', 'patrimoine_culturel', 'c_cult_soc_ser_patrim_cult', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Culture, société & services', 'culture_societe_service', 'Santé & social', 'sante_social', 'c_cult_soc_ser_sante_social', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Culture, société & services', 'culture_societe_service', 'Tourisme', 'tourisme', 'c_cult_soc_ser_tourisme', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Données génériques', 'donnee_generique', 'Action publique', 'action_publique', 'c_don_gen_action_publique', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Données génériques', 'donnee_generique', 'Découpage administratif', 'administratif', 'c_don_gen_administratif', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Eau', 'eau', 'Travaux & entretien', 'travail_action', 'c_eau_travail_action', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Eau', 'eau', 'Autres utilisations', 'utilisation_autre', 'c_eau_utilisation_autre', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Eau', 'eau', 'Zonages eau', 'zonages_eau', 'c_eau_zonages', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Foncier & sol', 'foncier_sol', 'Foncier agricole', 'foncier_agricole', 'c_fon_sol_agricole', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Foncier & sol', 'foncier_sol', 'Mutations foncières', 'mutation_fonciere', 'c_fon_sol_mutation', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Foncier & sol', 'foncier_sol', 'Occupation du sol', 'occupation_sol', 'c_fon_sol_occupation', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Foncier & sol', 'foncier_sol', 'Propriétés foncières', 'propriete_fonciere', 'c_fon_sol_propriete', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Forêt', 'foret', 'Description', 'description', 'c_foret_description', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Forêt', 'foret', 'Défense de la forêt contre les incendies', 'dfci', 'c_foret_dfci', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Forêt', 'foret', 'Gestion', 'gestion', 'c_foret_gestion', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Forêt', 'foret', 'Règlement', 'reglement', 'c_foret_reglement', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Forêt', 'foret', 'Transformation', 'transformation', 'c_foret_transformation', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Habitat & politique de la ville', 'habitat_politique_de_la_ville', 'Accession à la propriété', 'accession_propriete', 'c_hab_vil_access_propriete', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Habitat & politique de la ville', 'habitat_politique_de_la_ville', 'Besoin en logements', 'besoin_en_logement', 'c_hab_vil_besoin_logt', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Habitat & politique de la ville', 'habitat_politique_de_la_ville', 'Construction', 'construction', 'c_hab_vil_construction', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Habitat & politique de la ville', 'habitat_politique_de_la_ville', 'Habitat indigne', 'habitat_indigne', 'c_hab_vil_habitat_indigne', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Habitat & politique de la ville', 'habitat_politique_de_la_ville', 'Occupation des logements', 'occupation_logements', 'c_hab_vil_occupation_logt', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Habitat & politique de la ville', 'habitat_politique_de_la_ville', 'Parc locatif social', 'parc_locatif_social', 'c_hab_vil_parc_loc_social', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Habitat & politique de la ville', 'habitat_politique_de_la_ville', 'Parc de logements', 'parc_logements', 'c_hab_vil_parc_logt', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Habitat & politique de la ville', 'habitat_politique_de_la_ville', 'Politique', 'politique', 'c_hab_vil_politique', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Habitat & politique de la ville', 'habitat_politique_de_la_ville', 'Rénovation', 'renovation', 'c_hab_vil_renovation', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Mer & littoral', 'mer_littoral', 'Autres activités', 'autres_activites', 'c_mer_litt_autres_activites', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Mer & littoral', 'mer_littoral', 'Chasse maritime', 'chasse_maritime', 'c_mer_litt_chasse_maritime', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Mer & littoral', 'mer_littoral', 'Culture marine', 'culture_marine', 'c_mer_litt_culture_marine', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Mer & littoral', 'mer_littoral', 'Écologie du littoral', 'ecologie_littoral', 'c_mer_litt_ecol_littoral', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Mer & littoral', 'mer_littoral', 'Limites administratives spéciales', 'lim_admin_speciale', 'c_mer_litt_lim_admin_spe', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Mer & littoral', 'mer_littoral', 'Lutte anti-pollution', 'lutte_anti_pollution', 'c_mer_litt_lutte_anti_pollu', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Mer & littoral', 'mer_littoral', 'Navigation maritime', 'navigation_maritime', 'c_mer_litt_nav_maritime', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Mer & littoral', 'mer_littoral', 'Pêche maritime', 'peche_maritime', 'c_mer_litt_peche_maritime', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Mer & littoral', 'mer_littoral', 'Topographie', 'topographie', 'c_mer_litt_topographie', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Nature, paysage & biodiversité', 'nature_paysage_biodiversite', 'Chasse', 'chasse', 'c_nat_pays_bio_chasse', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Nature, paysage & biodiversité', 'nature_paysage_biodiversite', 'Inventaires nature & biodiversité', 'inventaire_nature_biodiversite', 'c_nat_pays_bio_invent_nat_bio', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Nature, paysage & biodiversité', 'nature_paysage_biodiversite', 'Inventaires paysages', 'inventaire_paysage', 'c_nat_pays_bio_invent_pays', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Nature, paysage & biodiversité', 'nature_paysage_biodiversite', 'Zonages nature', 'zonage_nature', 'c_nat_pays_bio_zonage_nat', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Nature, paysage & biodiversité', 'nature_paysage_biodiversite', 'Zonages paysages', 'zonage_paysage', 'c_nat_pays_bio_zonage_pays', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Nuisances', 'nuisance', 'Bruit', 'bruit', 'c_nuis_bruit', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Nuisances', 'nuisance', 'Déchets', 'dechet', 'c_nuis_dechet', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Nuisances', 'nuisance', 'Nuisances électromagnétiques', 'nuisance_electromagnetique', 'c_nuis_electromag', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Nuisances', 'nuisance', 'Pollution des sols', 'pollution_sol', 'c_nuis_pollu_sol', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Réseaux & énergie', 'reseau_energie_divers', 'Aménagement numérique du territoire', 'amenagement_numerique_territoire', 'c_res_energ_amgt_num_terri', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Réseaux & énergie', 'reseau_energie_divers', 'Autre', 'autre', 'c_res_energ_autre', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Réseaux & énergie', 'reseau_energie_divers', 'Électricité', 'electricite', 'c_res_energ_electricite', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Réseaux & énergie', 'reseau_energie_divers', 'Hydrocarbures', 'hydrocarbure', 'c_res_energ_hydrocarbure', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Réseaux & énergie', 'reseau_energie_divers', 'Télécommunications', 'telecommunication', 'c_res_energ_telecom', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Risques', 'risque', 'Avalanche', 'avalanche', 'c_risque_avalanche', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Risques', 'risque', 'Éruptions volcaniques', 'eruption_volcanique', 'c_risque_eruption_volcanique', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Risques', 'risque', 'Gestion des risques', 'gestion_risque', 'c_risque_gestion_risque', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Risques', 'risque', 'Inondations', 'inondation', 'c_risque_inondation', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Risques', 'risque', 'Mouvements de terrain', 'mouvement_terrain', 'c_risque_mouvement_terrain', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Risques', 'risque', 'Radon', 'radon', 'c_risque_radon', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Risques', 'risque', 'Risques miniers', 'risque_minier', 'c_risque_minier', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Risques', 'risque', 'Risques technologiques', 'risque_technologique', 'c_risque_techno', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Risques', 'risque', 'Zonages risques naturels', 'zonages_risque_naturel', 'c_risque_zonages_naturel', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Risques', 'risque', 'Zonages risques technologiques', 'zonages_risque_technologique', 'c_risque_zonages_techno', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Sites industriels & production', 'site_industriel_production', 'Mines, carrières & granulats', 'mine_carriere_granulats', 'c_indus_prod_mine_carriere_granul', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Sites industriels & production', 'site_industriel_production', 'Sites éoliens', 'site_eolien', 'c_indus_prod_eolien', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Sites industriels & production', 'site_industriel_production', 'Sites industriels', 'site_industriel', 'c_indus_prod_industriel', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Sites industriels & production', 'site_industriel_production', 'Sites de production d’énergie', 'site_production_energie', 'c_indus_prod_prod_energ', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Socio-économie', 'socio_economie', ' ', ' ', 'c_socio_eco', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Déplacements', 'transport_deplacement', 'Sécurité routière', 'securite_routiere', 'c_tr_depl_securite_routiere', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Déplacements', 'transport_deplacement', 'Transport collectif', 'tr_collectif', 'c_tr_depl_collectif', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Déplacements', 'transport_deplacement', 'Transport exceptionnel', 'tr_exceptionnel', 'c_tr_depl_exceptionnel', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Déplacements', 'transport_deplacement', 'Transport de marchandises', 'tr_marchandise', 'c_tr_depl_marchandise', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Déplacements', 'transport_deplacement', 'Transport de matières dangereuses', 'tr_matiere_dangereuse', 'c_tr_depl_mat_dangereuse', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Déplacements', 'transport_deplacement', 'Trafic', 'trafic', 'c_tr_depl_trafic', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Infrastructures de transport', 'transport_infrastructure', 'Aérien', 'aerien', 'c_tr_infra_aerien', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Infrastructures de transport', 'transport_infrastructure', 'Circulation douce', 'circulation_douce', 'c_tr_infra_circulation_douce', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Infrastructures de transport', 'transport_infrastructure', 'Ferroviaire', 'ferroviaire', 'c_tr_infra_ferroviaire', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Infrastructures de transport', 'transport_infrastructure', 'Fluvial', 'fluvial', 'c_tr_infra_fluvial', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Infrastructures de transport', 'transport_infrastructure', 'Maritime', 'maritime', 'c_tr_infra_maritime', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Infrastructures de transport', 'transport_infrastructure', 'Plateformes multimodales', 'plateforme_multimodale', 'c_tr_infra_plateforme_multimod', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Infrastructures de transport', 'transport_infrastructure', 'Routier', 'routier', 'c_tr_infra_routier', false, 'g_admin', NULL, 'g_consult')
            ) AS t (bloc, nomenclature, niv1, niv1_abr, niv2, niv2_abr, nom_schema, creation, producteur, editeur, lecteur)
            WHERE domaines IS NULL OR niv1 = ANY(domaines) OR niv1_abr = ANY(domaines)
    LOOP
        -- si le schéma n'était pas déjà référencé, il est ajouté
        -- (toujours comme non créé, même s'il existe par ailleurs dans la base)
        IF NOT item.nom_schema IN (SELECT gestion_schema_usr.nom_schema FROM z_asgard.gestion_schema_usr)
        THEN
            INSERT INTO z_asgard.gestion_schema_usr
                (bloc, nomenclature, niv1, niv1_abr, niv2, niv2_abr, nom_schema, creation, producteur, editeur, lecteur) VALUES
                (item.bloc, item.nomenclature, item.niv1, item.niv1_abr, item.niv2, item.niv2_abr, item.nom_schema, item.creation, item.producteur, item.editeur, item.lecteur) ;
            RAISE NOTICE 'Le schéma % a été ajouté à la table de gestion.', item.nom_schema ;
        
        -- sinon les champs de la nomenclature sont simplement mis à jour, le cas échéant
        ELSIF item.nom_schema IN (SELECT gestion_schema_usr.nom_schema FROM z_asgard.gestion_schema_usr)
        THEN
            UPDATE z_asgard.gestion_schema_usr
                SET nomenclature = item.nomenclature,
                    niv1 = item.niv1,
                    niv1_abr = item.niv1_abr,
                    niv2 = item.niv2,
                    niv2_abr = item.niv2_abr
                WHERE gestion_schema_usr.nom_schema = item.nom_schema
                    AND (NOT nomenclature = item.nomenclature
                        OR NOT coalesce(gestion_schema_usr.niv1, '') = coalesce(item.niv1, '')
                        OR NOT coalesce(gestion_schema_usr.niv1_abr, '') = coalesce(item.niv1_abr, '')
                        OR NOT coalesce(gestion_schema_usr.niv2, '') = coalesce(item.niv2, '')
                        OR NOT coalesce(gestion_schema_usr.niv2_abr, '') = coalesce(item.niv2_abr, '')) ;
            IF FOUND
            THEN
                RAISE NOTICE 'Les champs de la nomenclature ont été mis à jour pour le schéma %.', item.nom_schema ;
            END IF ;
    
        END IF ;
    END LOOP ;

    RETURN '__ FIN IMPORT NOMENCLATURE.' ;

EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                            e_hint = PG_EXCEPTION_HINT,
                            e_detl = PG_EXCEPTION_DETAIL,
                            e_errcode = RETURNED_SQLSTATE,
                            e_schema = SCHEMA_NAME ;
    
    RAISE EXCEPTION '%', z_asgard.asgard_prefixe_erreur(e_mssg, 'FIN')
        USING DETAIL = e_detl,
            HINT = e_hint,
            SCHEMA = e_schema,
            ERRCODE = e_errcode ;

END
$_$ ;

ALTER FUNCTION z_asgard_admin.asgard_import_nomenclature(text[])
    OWNER TO g_admin ;

COMMENT ON FUNCTION z_asgard_admin.asgard_import_nomenclature(text[]) IS 'ASGARD. Fonction qui importe dans la table de gestion les schémas manquants de la nomenclature nationale - ou de certains domaines de la nomenclature nationale listés en argument.' ;


------ 3.13 - REAFFECTATION DES PRIVILEGES D'UN RÔLE ------

-- Function: z_asgard_admin.asgard_reaffecte_role(text, text, boolean, boolean, boolean)

CREATE OR REPLACE FUNCTION z_asgard_admin.asgard_reaffecte_role(
    n_role text,
    n_role_cible text DEFAULT NULL,
    b_hors_asgard boolean DEFAULT False,
    b_privileges boolean DEFAULT True,
    b_default_acl boolean DEFAULT FALSE
)
    RETURNS text[]
    LANGUAGE plpgsql
    AS $_$
/* Transfère les privilèges d'un rôle à un autre, et en premier lieu ses 
   fonctions de producteur, éditeur et lecteur.

    Dans le contexte d'Asgard, il est fortement conseillé d'utiliser cette
    fonction plutôt qu'une commande REASSIGN OWNED, qui ne mettrait pas
    à jour la table de gestion en conséquence (et ne s'intéresse pas aux
    privilèges, seulement aux propriétés).
   
    Si aucun rôle cible n'est spécifié, les privilèges sont simplement supprimés 
    et g_admin devient producteur des schémas, le cas échéant.

    Avec "b_hors_asgard", il est possible de demander à la fonction de
    réaffecter aussi les droits portant sur des objets rattachés à des 
    schémas non référencés par Asgard, voire qui ne dépendent pas de schémas.

    Si elle n'est pas exécutée par un super-utilisateur, la fonction est
    susceptible d'échouer parce que l'utilisateur ne sera pas 
    habilité à modifier certaines propriétés ou privilèges. Le risque est
    plus grand si elle est aussi appliquée aux objets hors Asgard et les
    messages d'erreur seront moins explicites dans ce cas (messages bruts
    de PostgreSQL).

    Actuellement, deux types de dépendances au moins ne sont pas prises
    en charge par cette fonction : 
    - Les privilèges par défaut définis pour les objets créés par "n_role",
      même dans le cas où le paramètre "b_default_acl" vaut True.
    - Les privilèges conférés par "n_role" à d'autres rôles.

    Hormis pour les privilèges par défaut, la fonction ne préserve jamais 
    le qualificatif "GRANT OPTION" quand elle transfère des privilèges.

    Parameters
    ----------
    n_role : text
        Le nom du rôle dont on souhaite transférer ou supprimer les droits.
    n_role_cible : text, optional
        Le cas échéant, le nom du rôle auquel les droits doivent être
        transférés.
    b_hors_asgard : boolean, default False
        Si True, la propriété et les privilèges sur les objets des schémas
        non gérés par ASGARD ou hors schémas (par exemple la base), sont pris
        en compte. La propriété des objets reviendra à g_admin si aucun
        rôle cible n'est spécifié.
    b_privileges : boolean, default True
        Indique si, dans l'hypothèse où le rôle cible est spécifié, celui-ci 
        doit recevoir les privilèges et propriétés du rôle (True) ou seulement 
        ses propriétés (False).
    b_default_acl : boolean, default False
        Indique si les privilèges par défaut doivent être pris en compte (True) 
        ou non (False).

    Returns
    -------
    text[] or NULL
        Liste des bases sur lesquelles le rôle a encore des droits, sinon NULL.

    Raises
    ------
    invalid_parameter_value
        FRR1. Si le rôle spécifié par "n_role" n'existe pas.
        FRR2. Si le rôle spécifié par "n_role_cible" n'existe pas.
    insufficient_privilege
        FRR3. Si le rôle qui exécute la fonction n'hérite pas des droits
        de g_admin.

    Version notes
    -------------
    v1.5.0
        (M) La fonction préserve désormais le qualificatif "GRANT OPTION"
            pour le transfert des privilèges qu'elle gère directement
            (privilèges par défaut et privilèges sur les objets hors schémas).
            Pour les autres, les fonctions annexes qui construisent les commandes
            ont également été améliorées pour prendre en charge cet attribut.
        (m) D'autant que possible, recours à asgard_cherche_executant 
            pour trouver des rôles habilités à modifier les privilèges.
        (m) Ajout d'un contrôle vérifiant que le rôle qui exécute la
            fonction hérite des privilèges de g_admin.
        (m) Amélioration de la gestion des messages d'erreur.
        (m) Utilisation du mot clé ROUTINES plutôt que FUNCTIONS dans les
            commandes de définition de privilèges par défaut sous PostgreSQL
            11+, comme recommandé.
        (d) Enrichissement du descriptif.

*/
DECLARE
    item record ;
    n_producteur_cible text := coalesce(n_role_cible, 'g_admin') ;
    c record ;
    k int ;
    utilisateur text := current_user ;
    executant text ;
    l_db text[] ;
    e_mssg text ;
    e_detl text ;
    e_hint text ;
    e_schema text ;
    e_errcode text ;
BEGIN

    ------ CONTROLES PREALABLES ------
    -- la fonction est dans z_asgard_admin, donc seuls les membres de
    -- g_admin devraient pouvoir y accéder, mais au cas où :
    IF NOT pg_has_role('g_admin', 'USAGE')
    THEN
        RAISE EXCEPTION 'FRR3. Opération interdite. Vous devez être membre de g_admin pour exécuter cette fonction.'
            USING ERRCODE = 'insufficient_privilege' ;
    END IF ;

    -- existance du rôle
    IF NOT n_role IN (SELECT rolname FROM pg_catalog.pg_roles)
    THEN
        RAISE EXCEPTION 'FRR1. Echec. Le rôle % n''existe pas', n_role
            USING ERRCODE = 'invalid_parameter_value' ;
    END IF ;
    
    -- existance du rôle cible
    IF n_role_cible IS NOT NULL AND NOT n_role_cible IN (SELECT rolname FROM pg_catalog.pg_roles)
    THEN
        RAISE EXCEPTION 'FRR2. Echec. Le rôle % n''existe pas', n_role_cible
            USING ERRCODE = 'invalid_parameter_value' ;
    END IF ;
      
    IF NOT b_privileges
    THEN
        n_role_cible := NULL ;
    END IF ;
    
    ------ FONCTION DE PRODUCTEUR ------
    -- un même rôle ne pouvant être à la fois producteur et lecteur ou éditeur,
    -- on commence par révoquer les fonctions d'éditeur et lecteur du rôle cible
    -- sur les schémas dont il a vocation à devenir producteur 
    FOR item IN (SELECT * FROM z_asgard.gestion_schema_usr WHERE producteur = n_role)
    LOOP
        IF item.editeur = n_producteur_cible
        THEN
            UPDATE z_asgard.gestion_schema_usr
                SET editeur = NULL
                WHERE nom_schema = item.nom_schema ;
            RAISE NOTICE '... L''éditeur du schéma % a été supprimé.', item.nom_schema ;
        END IF ;
        
        IF item.lecteur = n_producteur_cible
        THEN
            UPDATE z_asgard.gestion_schema_usr
                SET lecteur = NULL
                WHERE nom_schema = item.nom_schema ;
            RAISE NOTICE '... Le lecteur du schéma % a été supprimé.', item.nom_schema ;
        END IF ;
        
        UPDATE z_asgard.gestion_schema_usr
            SET producteur = n_role_cible
            WHERE nom_schema = item.nom_schema ;
            RAISE NOTICE '... Le producteur du schéma % a été redéfini.', item.nom_schema ;
    END LOOP ;
    
    ------ FONCTION D'EDITEUR ------
    -- si le rôle cible était le producteur du schéma, on le garde en tant que
    -- producteur et on supprime juste l'éditeur
    -- si le rôle cible était le lecteur du schéma, on supprime le lecteur et on 
    -- désigne le rôle cible comme éditeur à la place du rôle initial
    FOR item IN (SELECT * FROM z_asgard.gestion_schema_usr WHERE editeur = n_role)
    LOOP
        IF item.producteur = n_role_cible
        THEN
            RAISE NOTICE 'Le rôle cible est actuellement producteur du schéma %.', item.nom_schema ;
            UPDATE z_asgard.gestion_schema_usr
                SET editeur = NULL
                WHERE nom_schema = item.nom_schema ;
            RAISE NOTICE '... L''éditeur du schéma % a été supprimé.', item.nom_schema ;
        ELSE
        
            IF item.lecteur = n_role_cible
            THEN
                UPDATE z_asgard.gestion_schema_usr
                    SET lecteur = NULL
                    WHERE nom_schema = item.nom_schema ;
                RAISE NOTICE '... Le lecteur du schéma % a été supprimé.', item.nom_schema ;
            END IF ;
            
            UPDATE z_asgard.gestion_schema_usr
                SET editeur = n_role_cible
                WHERE nom_schema = item.nom_schema ;
                RAISE NOTICE '... L''éditeur du schéma % a été redéfini.', item.nom_schema ;
        
        END IF ;
    END LOOP ;
    
    ------ FONCTION DE LECTEUR ------
    -- seulement si le rôle cible n'est pas déjà producteur ou éditeur du schéma
    FOR item IN (SELECT * FROM z_asgard.gestion_schema_usr WHERE lecteur = n_role)
    LOOP
        IF item.producteur = n_role_cible
        THEN
            RAISE NOTICE 'Le rôle cible est actuellement producteur du schéma %.', item.nom_schema ;
            UPDATE z_asgard.gestion_schema_usr
                SET lecteur = NULL
                WHERE nom_schema = item.nom_schema ;
            RAISE NOTICE '... Le lecteur du schéma % a été supprimé.', item.nom_schema ;
        ELSIF item.editeur = n_role_cible
        THEN
            RAISE NOTICE 'Le rôle cible est actuellement éditeur du schéma %.', item.nom_schema ;
            UPDATE z_asgard.gestion_schema_usr
                SET lecteur = NULL
                WHERE nom_schema = item.nom_schema ;
            RAISE NOTICE '... Le lecteur du schéma % a été supprimé.', item.nom_schema ;
        ELSE
            
            UPDATE z_asgard.gestion_schema_usr
                SET lecteur = n_role_cible
                WHERE nom_schema = item.nom_schema ;
                RAISE NOTICE '... Le lecteur du schéma % a été redéfini.', item.nom_schema ;
        
        END IF ;
    END LOOP ;
    
    ------ PROPRIETES HORS ASGARD ------
    IF b_hors_asgard
    THEN
        -- le rôle qui exécute la commande REASSIGN OWNED doit au moins hériter des
        -- droits des deux rôles visés, mais il aura aussi besoin du privilège
        -- CREATE sur la base s'il doit réaffecter la propriété de schémas, et
        -- du privilège CREATE sur les schémas dont il réaffecte des objets.
        -- Hors du contexte d'Asgard, il serait trop fastidieux de vérifier que
        -- l'utilisateur dispose bien de tous ces privilèges. Si ce n'est pas le cas, 
        -- il verra s'afficher les messages d'erreur bruts de PostgreSQL.
        EXECUTE format('REASSIGN OWNED BY %I TO %I', n_role, n_producteur_cible) ;
        RAISE NOTICE '> %', format('REASSIGN OWNED BY %I TO %I', n_role, n_producteur_cible) ;
        RAISE NOTICE '... Le cas échéant, la propriété des objets hors schémas référencés par ASGARD a été réaffectée.' ;
    END IF ;
    
    ------ PRIVILEGES RESIDUELS SUR LES SCHEMAS REFERENCES -------
    k := 0 ;

    -- choix d'un rôle habilité à exécuter les commandes (sinon
    -- asgard_cherche_executant émet une erreur)
    FOR item IN (SELECT * FROM z_asgard.gestion_schema_usr WHERE creation)
    LOOP
        FOR c IN (
            SELECT * 
                FROM z_asgard.asgard_synthese_role(
                    quote_ident(item.nom_schema)::regnamespace, 
                    quote_ident(n_role)::regrole
                )
        )
        LOOP
            -- choix d'un rôle habilité à exécuter les commandes (sinon
            -- asgard_cherche_executant émet une erreur)
            executant := z_asgard.asgard_cherche_executant(
                'PRIVILEGES', 
                new_producteur := item.producteur
            ) ;
            EXECUTE format('SET ROLE %I', executant) ;

            EXECUTE format(z_asgard.asgard_grant_to_revoke(c.commande), n_role) ;
            RAISE NOTICE '> %', format(z_asgard.asgard_grant_to_revoke(c.commande), n_role) ;
            
            IF n_role_cible IS NOT NULL
            THEN
                EXECUTE format(c.commande, n_role_cible) ;
                RAISE NOTICE '> %', format(c.commande, n_role_cible) ;
            END IF ;

            EXECUTE format('SET ROLE %I', utilisateur) ;
            
            k := k + 1 ;
        END LOOP ;        
    END LOOP ;
    IF k > 0
    THEN
        IF n_role_cible IS NULL
        THEN
            RAISE NOTICE '... Les privilèges résiduels du rôle % sur les schémas référencés par ASGARD ont été révoqués.', n_role ;
        ELSE
            RAISE NOTICE '... Les privilèges résiduels du rôle % sur les schémas référencés par ASGARD ont été réaffectés.', n_role ;
        END IF ;
    END IF ;
    
    ------ PRIVILEGES RESIDUELS SUR LES SCHEMAS NON REFERENCES ------
    IF b_hors_asgard
    THEN
        -- Pour les objets des schémas hors Asgard, vérifier que l'utilisateur
        -- dispose des privilèges nécessaires serait trop fastidieux. Si
        -- ce n'est pas le cas, il verra s'afficher les messages d'erreur
        -- bruts de PostgreSQL.
        k := 0 ;
        FOR item IN (
            SELECT * 
                FROM pg_catalog.pg_namespace
                    LEFT JOIN z_asgard.gestion_schema_usr
                        ON nspname::text = nom_schema AND creation
                WHERE nom_schema IS NULL
        )
        LOOP
            FOR c IN (
                SELECT * 
                    FROM z_asgard.asgard_synthese_role(
                        quote_ident(item.nspname::text)::regnamespace, 
                        quote_ident(n_role)::regrole
                    )
            )
            LOOP
                EXECUTE format(z_asgard.asgard_grant_to_revoke(c.commande), n_role) ;
                RAISE NOTICE '> %', format(z_asgard.asgard_grant_to_revoke(c.commande), n_role) ;
                
                IF n_role_cible IS NOT NULL
                THEN
                    EXECUTE format(c.commande, n_role_cible) ;
                    RAISE NOTICE '> %', format(c.commande, n_role_cible) ;
                END IF ;
                
                k := k + 1 ;
            END LOOP ;        
        END LOOP ;
        IF k > 0
        THEN
            IF n_role_cible IS NULL
            THEN
                RAISE NOTICE '... Les privilèges résiduels du rôle % sur les schémas non référencés par ASGARD ont été révoqués.', n_role ;
            ELSE
                RAISE NOTICE '... Les privilèges résiduels du rôle % sur les schémas non référencés par ASGARD ont été réaffectés.', n_role ;
            END IF ;
        END IF ;
    END IF ;
    
    ------ ACL PAR DEFAUT ------
    IF b_default_acl
    THEN
        k := 0 ;
        FOR item IN (
            SELECT
                format(
                    'ALTER DEFAULT PRIVILEGES FOR ROLE %s%s REVOKE %s ON %s FROM %I',
                    pg_default_acl.defaclrole::regrole,
                    CASE WHEN pg_default_acl.defaclnamespace = 0 THEN ''
                        ELSE format(
                            ' IN SCHEMA %s', 
                            pg_default_acl.defaclnamespace::regnamespace
                        ) END,
                    acl.privilege,
                    t.typ_lg,
                    n_role
                ) AS revoke_commande,
                CASE WHEN n_role_cible IS NOT NULL 
                THEN 
                    format(
                        'ALTER DEFAULT PRIVILEGES FOR ROLE %s%s GRANT %s ON %s TO %I%s',
                        pg_default_acl.defaclrole::regrole,
                        CASE WHEN pg_default_acl.defaclnamespace = 0 THEN ''
                            ELSE format(
                                ' IN SCHEMA %s', 
                                pg_default_acl.defaclnamespace::regnamespace
                            ) END,
                        acl.privilege,
                        t.typ_lg,
                        n_role_cible,
                        CASE WHEN acl.grantable THEN ' WITH GRANT OPTION'
                            ELSE '' END
                    ) END AS grant_commande,
                pg_roles.rolname,
                pg_default_acl.defaclrole
                FROM pg_catalog.pg_default_acl
                    INNER JOIN pg_catalog.pg_roles 
                        ON pg_default_acl.defaclrole = pg_roles.oid
                    LEFT JOIN z_asgard.gestion_schema_etr
                        ON pg_default_acl.defaclnamespace = gestion_schema_etr.oid_schema,
                    aclexplode(pg_default_acl.defaclacl) AS acl (
                        grantor, grantee, privilege, grantable
                    ),
                    unnest(
                        ARRAY['TABLES', 'SEQUENCES',
                            CASE WHEN current_setting('server_version_num')::int < 110000
                                THEN 'FUNCTIONS' ELSE 'ROUTINES' END,
                            -- à ce stade FUNCTIONS et ROUTINES sont équivalents, mais
                            -- ROUTINES est préconisé
                            'TYPES', 'SCHEMAS'],
                        ARRAY['r', 'S', 'f', 'T', 'n']
                    ) AS t (typ_lg, typ_crt)
                WHERE pg_default_acl.defaclobjtype = t.typ_crt
                    AND (gestion_schema_etr.oid_schema IS NOT NULL OR b_hors_asgard)
                    AND acl.grantee = quote_ident(n_role)::regrole
            )
        LOOP

            -- choix d'un rôle habilité à exécuter les commandes (sinon
            -- asgard_cherche_executant émet une erreur)
            executant := z_asgard.asgard_cherche_executant(
                'ALTER DEFAULT PRIVILEGES', 
                new_producteur := item.rolname
            ) ;
            EXECUTE format('SET ROLE %I', executant) ;

            IF n_role_cible IS NOT NULL
            THEN
                EXECUTE item.grant_commande ;
                RAISE NOTICE '> %', item.grant_commande ;
            END IF ;
            
            EXECUTE item.revoke_commande ;
            RAISE NOTICE '> %', item.revoke_commande ;

            EXECUTE format('SET ROLE %I', utilisateur) ;

            k := k + 1 ;

        END LOOP ;
        IF k > 0
        THEN
            IF n_role_cible IS NULL
            THEN
                RAISE NOTICE '... Les privilèges par défaut du rôle % ont été supprimés.', n_role ;
            ELSE
                RAISE NOTICE '... Les privilèges par défaut du rôle % ont été transférés.', n_role ;
            END IF ;
        END IF ;
    END IF ;
    
    ------- OBJETS HORS SCHEMAS ------
    IF b_hors_asgard
    THEN
        k := 0 ;
        FOR c IN (
            -- bases de données
            SELECT
                format(
                    'GRANT %s ON DATABASE %I TO %%I%s', 
                    privilege, 
                    datname,
                    CASE WHEN acl.grantable THEN ' WITH GRANT OPTION' ELSE '' END
                ) AS commande
                FROM pg_catalog.pg_database,
                    aclexplode(datacl) AS acl (grantor, grantee, privilege, grantable)
                WHERE datacl IS NOT NULL
                    AND grantee = quote_ident(n_role)::regrole
            UNION
            -- tablespaces
            SELECT
                format(
                    'GRANT %s ON TABLESPACE %I TO %%I%s', 
                    privilege, 
                    spcname,
                    CASE WHEN acl.grantable THEN ' WITH GRANT OPTION' ELSE '' END
                ) AS commande
                FROM pg_catalog.pg_tablespace,
                    aclexplode(spcacl) AS acl (grantor, grantee, privilege, grantable)
                WHERE spcacl IS NOT NULL
                    AND grantee = quote_ident(n_role)::regrole
            UNION
            -- foreign data wrappers
            SELECT
                format(
                    'GRANT %s ON FOREIGN DATA WRAPPER %I TO %%I%s', 
                    privilege, 
                    fdwname,
                    CASE WHEN acl.grantable THEN ' WITH GRANT OPTION' ELSE '' END
                ) AS commande
                FROM pg_catalog.pg_foreign_data_wrapper,
                    aclexplode(fdwacl) AS acl (grantor, grantee, privilege, grantable)
                WHERE fdwacl IS NOT NULL
                    AND grantee = quote_ident(n_role)::regrole
            UNION
            -- foreign servers
            SELECT
                format(
                    'GRANT %s ON FOREIGN SERVER %I TO %%I%s', 
                    privilege, 
                    srvname,
                    CASE WHEN acl.grantable THEN ' WITH GRANT OPTION' ELSE '' END
                ) AS commande
                FROM pg_catalog.pg_foreign_server,
                    aclexplode(srvacl) AS acl (grantor, grantee, privilege, grantable)
                WHERE srvacl IS NOT NULL
                    AND grantee = quote_ident(n_role)::regrole
            UNION
            -- langages
            SELECT
                format(
                    'GRANT %s ON LANGUAGE %I TO %%I%s', 
                    privilege, 
                    lanname,
                    CASE WHEN acl.grantable THEN ' WITH GRANT OPTION' ELSE '' END
                ) AS commande
                FROM pg_catalog.pg_language,
                    aclexplode(lanacl) AS acl (grantor, grantee, privilege, grantable)
                WHERE lanacl IS NOT NULL
                    AND grantee = quote_ident(n_role)::regrole
            UNION        
            -- large objects
            SELECT 
                format(
                    'GRANT %s ON LARGE OBJECT %I TO %%I%s', 
                    privilege, 
                    pg_largeobject_metadata.oid::text,
                    CASE WHEN acl.grantable THEN ' WITH GRANT OPTION' ELSE '' END
                ) AS commande
                FROM pg_catalog.pg_largeobject_metadata,
                    aclexplode(lomacl) AS acl (grantor, grantee, privilege, grantable)
                WHERE lomacl IS NOT NULL
                    AND grantee = quote_ident(n_role)::regrole
        ) LOOP
            EXECUTE format(z_asgard.asgard_grant_to_revoke(c.commande), n_role) ;
            RAISE NOTICE '> %', format(z_asgard.asgard_grant_to_revoke(c.commande), n_role) ;
            
            IF n_role_cible IS NOT NULL
            THEN
                EXECUTE format(c.commande, n_role_cible) ;
                RAISE NOTICE '> %', format(c.commande, n_role_cible) ;
            END IF ;
            
            k := k + 1 ;
        END LOOP ;
        IF k > 0
        THEN
            IF n_role_cible IS NULL
            THEN
                RAISE NOTICE '... Les privilèges résiduels du rôle % sur les objets hors schémas ont été révoqués.', n_role ;
            ELSE
                RAISE NOTICE '... Les privilèges résiduels du rôle % sur les objets hors schémas ont été réaffectés.', n_role ;
            END IF ;
        END IF ;
    END IF ;

    ------ RESULTAT ------
    SELECT array_agg(DISTINCT pg_database.datname ORDER BY pg_database.datname)
        INTO l_db
        FROM pg_catalog.pg_shdepend
            LEFT JOIN pg_catalog.pg_database
                ON pg_shdepend.dbid = pg_database.oid
                    OR pg_shdepend.classid = 'pg_database'::regclass AND pg_shdepend.objid = pg_database.oid
        WHERE refclassid = 'pg_authid'::regclass
            AND refobjid = quote_ident(n_role)::regrole ;
    
    RETURN l_db ;

EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                            e_hint = PG_EXCEPTION_HINT,
                            e_detl = PG_EXCEPTION_DETAIL,
                            e_errcode = RETURNED_SQLSTATE,
                            e_schema = SCHEMA_NAME ;
         
    RAISE EXCEPTION '%', z_asgard.asgard_prefixe_erreur(e_mssg, 'FRR')
        USING DETAIL = e_detl,
            HINT = e_hint,
            SCHEMA = e_schema,
            ERRCODE = e_errcode ;

END
$_$ ;

ALTER FUNCTION z_asgard_admin.asgard_reaffecte_role(text, text, boolean, boolean, boolean)
    OWNER TO g_admin ;

COMMENT ON FUNCTION z_asgard_admin.asgard_reaffecte_role(text, text, boolean, boolean, boolean) IS 'ASGARD. Réaffecte les privilèges et propriétés d''un rôle à un autre.' ;


------ 3.14 - REINITIALISATION DES PRIVILEGES SUR TOUS LES SCHEMAS ------

-- Function: z_asgard_admin.asgard_initialise_all_schemas(integer)

CREATE OR REPLACE FUNCTION z_asgard_admin.asgard_initialise_all_schemas(
    variante integer DEFAULT 0
)
    RETURNS varchar[]
    LANGUAGE plpgsql
    AS $_$
/* Réinitialise les privilèges sur tous les schémas référencés par ASGARD 
   en une seule commande.

    Pour les schémas d'ASGARD, même s'ils n'ont pas été référencés,
    les droits nécessaires au bon fonctionnement du système seront
    rétablis.

    Il faut au moins être membre de g_admin pour exécuter cette 
    fonction, mais il est conseillé d'utiliser un super-utilisateur
    pour assurer une réinitialisation complète. Le cas échéant, les
    corrections qui n'ont pas pu être effectuées faute de droits
    suffisants seront signalées.

    Parameters
    ----------
    variante : int, default 0
        Le numéro de la version à appliquer. La variante 0 est la 
        forme standard de la fonction, appliquée à tous les schémas
        référencés et, qu'ils soient référencés ou non, les schémas 
        d'Asgard. Elle réinitialise les privilèges et vérifie que
        tous les objets appartiennent au producteur du schéma
        (ou, dans le cas des schémas d'Asgard, à un rôle pertinent).
        Si 1, la fonction ne fera que s'assurer que tous les objets 
        appartiennent au propriétaire du schéma. 
        Si 2, la fonction ne s'exécutera que sur les schémas d'ASGARD.

    Returns
    -------
    varchar[]
        NULL si la requête s'est exécutée normalement, sinon la liste
        des schémas qui n'ont pas pu être traités. Se reporter dans ce cas à
        l'onglet des messages pour le détail des erreurs.

    Raises
    ------
    insufficient_privilege
        FAS1. Si le rôle qui exécute la fonction n'hérite pas des droits
        de g_admin.
    data_exception
        FAS2. Si la vue z_asgard.gestion_schema_usr n'existe pas.

    Version notes
    -------------
    v1.5.0
        (m) Hormis pour s'assurer qu'il est membre de g_admin, la fonction 
            ne contrôle plus directement les privilèges de l'utilisateur 
            courant - les fonctions annexes qu'elle appelle s'en chargent.
        (m) Amélioration de la gestion des messages d'erreur.
        (m) Petite simplification du code.
        (d) Enrichissement du descriptif.

*/
DECLARE
    s record ;
    l varchar[] ;
    k integer ;
    e_mssg text ;
    e_hint text ;
    e_detl text ;
    e_errcode text ;
    e_schema text ;
    v_prop oid ;
    t text ;
BEGIN

    ------ CONTROLES PREALABLES ------
    -- la fonction est dans z_asgard_admin, donc seuls les membres de
    -- g_admin devraient pouvoir y accéder, mais au cas où :
    IF NOT pg_has_role('g_admin', 'USAGE')
    THEN
        RAISE EXCEPTION 'FAS1. Opération interdite. Vous devez être membre de g_admin pour exécuter cette fonction.'
            USING ERRCODE = 'insufficient_privilege' ;
    END IF ;
    
    -- permission manquante du propriétaire de la vue gestion_schema_usr
    -- (en principe g_admin_ext) sur le schéma z_asgard_admin ou la table
    -- gestion_schema :
    SELECT relowner INTO v_prop
        FROM pg_catalog.pg_class
        WHERE relname = 'gestion_schema_usr' 
            AND relnamespace = 'z_asgard'::regnamespace::oid ;
        
    IF NOT FOUND
    THEN
        RAISE EXCEPTION 'FAS2. Echec. La vue z_asgard.gestion_schema_usr est introuvable.'
            USING ERRCODE = 'data_exception' ;
    END IF ;
    
    IF NOT has_schema_privilege(v_prop, 'z_asgard_admin', 'USAGE')
        OR NOT has_table_privilege(v_prop, 'z_asgard_admin.gestion_schema', 'SELECT')
    THEN
        RAISE NOTICE '(temporaire) droits a minima pour le propriétaire de la vue gestion_schema_usr :' ;
    
        IF NOT has_schema_privilege(v_prop, 'z_asgard_admin', 'USAGE')
        THEN
            t := 'GRANT USAGE ON SCHEMA z_asgard_admin TO ' || v_prop::regrole::text ;
            EXECUTE t ;
            RAISE NOTICE '> %', t ;
        END IF ;
        
        IF NOT has_table_privilege(v_prop, 'z_asgard_admin.gestion_schema', 'SELECT')
        THEN
            t := 'GRANT SELECT ON TABLE z_asgard_admin.gestion_schema TO ' || v_prop::regrole::text ;
            EXECUTE t ;
            RAISE NOTICE '> %', t ;
        END IF ;
        
        RAISE NOTICE '---------------------------------' ;
    END IF ;
    
    ------ NETTOYAGE ------
    FOR s IN (
            SELECT 2 AS n, nom_schema, producteur
                FROM z_asgard.gestion_schema_usr
                WHERE creation AND NOT nom_schema = 'z_asgard'
            UNION VALUES (1, 'z_asgard', 'g_admin_ext'), (0, 'z_asgard_admin', 'g_admin')
            ORDER BY n, nom_schema
            )
    LOOP
        
        IF s.nom_schema IN ('z_asgard', 'z_asgard_admin') 
            OR variante < 2
        THEN
        
            -- si le rôle courant ne dispose pas des privilèges nécessaires pour 
            -- nettoyer certains schémas, les fonctions appelées le détecteront.

            BEGIN
                IF variante = 1
                    AND NOT s.nom_schema IN ('z_asgard', 'z_asgard_admin')
                THEN
                    -- lancement de la fonction de nettoyage des propriétaires
                    IF quote_ident(s.producteur) = (
                        SELECT nspowner::regrole::text 
                            FROM pg_catalog.pg_namespace 
                            WHERE nspname = s.nom_schema
                        )
                    THEN
                        -- version objets seuls si le propriétaire du schéma est bon
                        RAISE NOTICE '(ré)attribution de la propriété des objets au rôle producteur du schéma :' ;
                        
                        SELECT z_asgard.asgard_admin_proprietaire(
                            s.nom_schema, s.producteur, False
                        ) INTO k ;
                        
                        IF k = 0
                        THEN
                            RAISE NOTICE '> néant' ;
                        END IF ;

                    ELSE
                        -- version schéma + objets sinon
                        RAISE NOTICE '(ré)attribution de la propriété du schéma et des objets au rôle producteur du schéma :' ;
                        PERFORM z_asgard.asgard_admin_proprietaire(s.nom_schema, s.producteur) ;
                    
                    END IF ;
                        
                ELSE
                    -- lancement de la fonction de réinitialisation des droits,
                    -- qui traite à la fois les propriétaires et les privilèges
                    PERFORM z_asgard.asgard_initialise_schema(s.nom_schema) ;
                        
                END IF ;
                
                RAISE NOTICE '... Le schéma % a été traité', s.nom_schema ;
                
            EXCEPTION WHEN OTHERS THEN
                GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                                        e_hint = PG_EXCEPTION_HINT,
                                        e_detl = PG_EXCEPTION_DETAIL,
                                        e_errcode = RETURNED_SQLSTATE,
                                        e_schema = SCHEMA_NAME ;
                RAISE NOTICE '... ECHEC. Schéma % non traité.', s.nom_schema ;
                RAISE NOTICE 'Erreur rencontrée : %', e_mssg
                    USING DETAIL = e_detl,
                        HINT = e_hint,
                        SCHEMA = e_schema,
                        ERRCODE = e_errcode ;
                l := array_append(l, s.nom_schema) ;
            END ;
          
        RAISE NOTICE '---------------------------------' ;
        END IF ;
    
    END LOOP ;
    
    ------ RESULTAT ------
    RETURN l ;

EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                            e_hint = PG_EXCEPTION_HINT,
                            e_detl = PG_EXCEPTION_DETAIL,
                            e_errcode = RETURNED_SQLSTATE,
                            e_schema = SCHEMA_NAME ;
    
    RAISE EXCEPTION '%', z_asgard.asgard_prefixe_erreur(e_mssg, 'FAS')
        USING DETAIL = e_detl,
            HINT = e_hint,
            SCHEMA = e_schema,
            ERRCODE = e_errcode ;
               
END
$_$ ;

ALTER FUNCTION z_asgard_admin.asgard_initialise_all_schemas(integer)
    OWNER TO g_admin ;

COMMENT ON FUNCTION z_asgard_admin.asgard_initialise_all_schemas(integer) IS 'ASGARD. Fonction qui réinitialise les droits sur l''ensemble des schémas référencés.' ;


------ 3.15 - TRANSFORMATION D'UN NOM DE RÔLE POUR COMPARAISON AVEC LES CHAMPS ACL ------  [supprimé version 1.4.0]

-- Function: z_asgard.asgard_role_trans_acl(regrole)


------ 3.16 - DIAGNOSTIC DES DROITS NON STANDARDS ------

-- Function: z_asgard_admin.asgard_diagnostic(text[])

CREATE OR REPLACE FUNCTION z_asgard_admin.asgard_diagnostic(cibles text[] DEFAULT NULL::text[])
    RETURNS TABLE (
        nom_schema text, 
        nom_objet text, 
        typ_objet text, 
        critique boolean, 
        anomalie text
    )
    LANGUAGE plpgsql
    AS $_$
/* Pour tous les schémas actifs référencés par Asgard, liste les écarts
   entre les droits effectifs et les droits standards.

    Cette fonction peut avoir une durée d'exécution conséquente
    si elle est appliquée à un grand nombre de schémas.
    
    Les "anomalies" détectée peuvent être parfaitement justifiées
    si elles résultent d'une personnalisation volontaire des
    droits sur certains objets.

    Parameters
    ----------
    cibles : text[], optional
        Permet de restreindre le diagnostic à la liste de schémas
        spécifiés.
    
    Returns
    -------
    table (nom_schema : text, nom_objet : text, typ_objet : text,
    critique : boolean, anomalie : text)
        Une table avec quatre attributs :
        
        * "nom_schema" est le nom du schéma.
        * "nom_objet" est le nom de l'objet concerné.
        * "typ_objet" est le type d'objet.
        * "critique" vaut True si l'anomalie est problématique pour
          le bon fonctionnement d'Asgard (et doit être corrigée au
          plus tôt), False si elle est bénigne.
        * "anomalie" est une description de l'anomalie.
    
    Examples
    -------- 
    SELECT * FROM z_asgard_admin.asgard_diagnostic() ;
    SELECT * FROM z_asgard_admin.asgard_diagnostic(ARRAY['schema_1', 'schema_2']) ;

    Raises
    ------
    invalid_parameter_value
        FDD1. Si au moins un des schémas listés via l'argument "cible"
        n'est pas référencé dans la table de gestion d'Asgard.
    insufficient_privilege
        FDD2. Si le rôle qui exécute la fonction n'hérite pas des droits
        de g_admin.

    Version notes
    -------------
    v1.5.0
        (m) Suppression des commandes spécifiques au schéma "z_asgard_admin" :
            désormais considéré comme un schéma système non référençable, il
            ne pourra plus être examiné par cette fonction (et le fait que tous
            ses objets n'aient pas le même propriétaire aurait été difficile
            à gérer).
        (m) Ajout d'un contrôle vérifiant que le rôle qui exécute la
            fonction hérite des privilèges de g_admin.
        (m) Amélioration de la gestion des messages d'erreur.
        (m) Recours à asgard_table_owner_privileges_codes plutôt qu'une liste en
            dur pour les privilèges attendus du producteur d'une
            table ou assimilé, pour prendre en compte l'introduction
            du privilège MAINTAIN par PostgreSQL 17.
    
*/
DECLARE
    item record ;
    catalogue record ;
    objet record ;
    asgard record ;
    s text ;
    cibles_trans text ;
    e_mssg text ;
    e_detl text ;
    e_hint text ;
    e_schema text ;
    e_errcode text ;
BEGIN

    ------ CONTROLES ET PREPARATION ------
    -- la fonction est dans z_asgard_admin, donc seuls les membres de
    -- g_admin devraient pouvoir y accéder, mais au cas où :
    IF NOT pg_has_role('g_admin', 'USAGE')
    THEN
        RAISE EXCEPTION 'FDD2. Opération interdite. Vous devez être membre de g_admin pour exécuter cette fonction.'
            USING ERRCODE = 'insufficient_privilege' ;
    END IF ;

    cibles := nullif(nullif(cibles, ARRAY[]::text[]), ARRAY[NULL]::text[]) ;
    
    IF cibles IS NOT NULL
    THEN
        
        FOREACH s IN ARRAY cibles
        LOOP

            IF NOT s IN (
                SELECT gestion_schema_etr.nom_schema 
                    FROM z_asgard.gestion_schema_etr 
                    WHERE gestion_schema_etr.creation
                )
            THEN
                RAISE EXCEPTION 'FDD1. Le schéma % n''existe pas ou n''est pas référencé dans la table de gestion d''ASGARD.', s
                    USING ERRCODE = 'invalid_parameter_value' ;
            ELSIF s IS NOT NULL
            THEN
                IF cibles_trans IS NULL
                THEN
                    cibles_trans := quote_literal(s) ;
                ELSE
                    cibles_trans := format('%s, %L', cibles_trans, s) ;
                END IF ;
            END IF ;

        END LOOP ;
        
        cibles_trans := format('ARRAY[%s]', cibles_trans) ;
        cibles_trans := nullif(cibles_trans, 'ARRAY[]') ;

    END IF ;

    ------ DIAGNOSTIC ------
    FOR item IN EXECUTE 
        E'SELECT
            gestion_schema_etr.nom_schema,
            gestion_schema_etr.oid_schema,
            r1.rolname AS producteur,
            r1.oid AS oid_producteur,
            CASE WHEN editeur = ''public'' THEN ''public'' ELSE r2.rolname END AS editeur,
            r2.oid AS oid_editeur,
            CASE WHEN lecteur = ''public'' THEN ''public'' ELSE r3.rolname END AS lecteur,
            r3.oid AS oid_lecteur
            FROM z_asgard.gestion_schema_etr
                LEFT JOIN pg_catalog.pg_roles AS r1 ON r1.oid = oid_producteur
                LEFT JOIN pg_catalog.pg_roles AS r2 ON r2.oid = oid_editeur
                LEFT JOIN pg_catalog.pg_roles AS r3 ON r3.oid = oid_lecteur
            WHERE gestion_schema_etr.creation'
            || CASE WHEN cibles_trans IS NOT NULL
                THEN format(' AND gestion_schema_etr.nom_schema = ANY (%s)', cibles_trans)
                ELSE '' END
    LOOP
        FOR catalogue IN (
            SELECT *
                FROM
                -- liste des objets à traiter
                unnest(
                    -- catalogue de l'objet
                    ARRAY['pg_class', 'pg_class', 'pg_class', 'pg_class', 'pg_class', 'pg_class',
                            'pg_proc', 'pg_type', 'pg_type', 'pg_conversion', 'pg_operator', 'pg_collation',
                            'pg_ts_dict', 'pg_ts_config', 'pg_opfamily', 'pg_opclass', 'pg_statistic_ext', 'pg_namespace',
                            'pg_default_acl', 'pg_default_acl', 'pg_default_acl', 'pg_default_acl', 'pg_attribute'],
                    -- préfixe utilisé pour les attributs du catalogue
                    ARRAY['rel', 'rel', 'rel', 'rel', 'rel', 'rel',
                            'pro', 'typ', 'typ', 'con', 'opr', 'coll',
                            'dict', 'cfg', 'opf', 'opc', 'stx', 'nsp',
                            'defacl', 'defacl', 'defacl', 'defacl', 'att'],
                    -- si dinstinction selon un attribut, nom de cet attribut
                    ARRAY['relkind', 'relkind', 'relkind', 'relkind', 'relkind', 'relkind',
                            NULL, 'typtype', 'typtype', NULL, NULL, NULL,
                            NULL, NULL, NULL, NULL, NULL, NULL,
                            'defaclobjtype', 'defaclobjtype', 'defaclobjtype', 'defaclobjtype', NULL],
                    -- si distinction selon un attribut, valeur de cet attribut
                    ARRAY['^r$', '^p$', '^v$', '^m$', '^f$', '^S$',
                            NULL, '^d$', '^[^d]$', NULL, NULL, NULL,
                            NULL, NULL, NULL, NULL, NULL, NULL,
                            '^r$', '^S$', '^f$', '^T$', NULL],
                    -- nom lisible de l'objet
                    ARRAY['table', 'table partitionnée', 'vue', 'vue matérialisée', 'table étrangère', 'séquence',
                            'routine', 'domaine', 'type', 'conversion', 'opérateur', 'collationnement',
                            'dictionnaire de recherche plein texte', 'configuration de recherche plein texte',
                                'famille d''opérateurs', 'classe d''opérateurs', 'objet statistique étendu', 'schéma',
                            'privilège par défaut sur les tables', 'privilège par défaut sur les séquences',
                                'privilège par défaut sur les fonctions', 'privilège par défaut sur les types', 'attribut'],
                    -- contrôle des droits ?
                    ARRAY[true, true, true, true, true, true,
                            true, true, true, false, false, false,
                            false, false, false, false, false, true,
                            true, true, true, true, true],
                    -- droits attendus pour le lecteur du schéma sur l'objet
                    ARRAY['r', 'r', 'r', 'r', 'r', 'r',
                            NULL, NULL, NULL, NULL, NULL, NULL,
                            NULL, NULL, NULL, NULL, NULL, 'U',
                            NULL, NULL, NULL, NULL, NULL],
                    -- droits attendus pour l'éditeur du schéma sur l'objet
                    ARRAY['rawd', 'rawd', 'rawd', 'rawd', 'rawd', 'rU',
                            NULL, NULL, NULL, NULL, NULL, NULL,
                            NULL, NULL, NULL, NULL, NULL, 'U',
                            NULL, NULL, NULL, NULL, NULL],
                    -- droits attendus pour le producteur du schéma sur l'objet
                    ARRAY[z_asgard.asgard_table_owner_privileges_codes(), z_asgard.asgard_table_owner_privileges_codes(), z_asgard.asgard_table_owner_privileges_codes(), z_asgard.asgard_table_owner_privileges_codes(), z_asgard.asgard_table_owner_privileges_codes(), 'rwU',
                            'X', 'U', 'U', NULL, NULL, NULL,
                            NULL, NULL, NULL, NULL, NULL, 'UC',
                            'rawdDxt', 'rwU', 'X', 'U', NULL],
                    -- droits par défaut de public sur les types et les fonctions
                    ARRAY[NULL, NULL, NULL, NULL, NULL, NULL,
                            'X', 'U', 'U', NULL, NULL, NULL,
                            NULL, NULL, NULL, NULL, NULL, NULL,
                            NULL, NULL, NULL, NULL, NULL],
                    -- si non présent dans PG 9.5, version d'apparition
                    -- sous forme numérique
                    ARRAY[NULL, NULL, NULL, NULL, NULL, NULL,
                            NULL, NULL, NULL, NULL, NULL, NULL,
                            NULL, NULL, NULL, NULL, 100000, NULL,
                            NULL, NULL, NULL, NULL, NULL],
                    -- géré automatiquement par ASGARD ?
                    ARRAY[true, true, true, true, true, true,
                            true, true, true, true, true, true,
                            true, true, false, false, false, true,
                            NULL, NULL, NULL, NULL, true]
                    ) AS l (catalogue, prefixe, attrib_genre, valeur_genre, lib_obj, droits, drt_lecteur,
                        drt_editeur, drt_producteur, drt_public, min_version, asgard_auto)
            )
        LOOP
            IF catalogue.min_version IS NULL
                    OR current_setting('server_version_num')::int >= catalogue.min_version
            THEN
                FOR objet IN EXECUTE '
                    SELECT ' ||
                        CASE WHEN NOT catalogue.catalogue = 'pg_attribute' THEN
                            catalogue.catalogue || '.oid AS objoid, ' ELSE '' END ||
                        CASE WHEN catalogue.catalogue = 'pg_default_acl' THEN ''
                            WHEN catalogue.catalogue = 'pg_attribute'
                                THEN '(z_asgard.asgard_parse_relident(attrelid::regclass))[2] || '' ('' || ' ||
                                    catalogue.prefixe || 'name || '')'' AS objname, '
                            ELSE catalogue.prefixe || 'name::text AS objname, ' END || '
                        rolname AS objowner' ||
                        CASE WHEN catalogue.droits THEN ', ' || catalogue.prefixe || 'acl AS objacl' ELSE '' END || '
                        FROM pg_catalog.' || catalogue.catalogue || '
                            LEFT JOIN pg_catalog.pg_roles ON pg_roles.oid = ' ||
                                CASE WHEN catalogue.catalogue = 'pg_default_acl' THEN 'defaclrole'
                                    WHEN catalogue.catalogue = 'pg_attribute' THEN 'NULL'
                                    ELSE  catalogue.prefixe || 'owner' END || ' 
                        WHERE ' || CASE WHEN catalogue.catalogue = 'pg_attribute'
                                    THEN 'quote_ident((z_asgard.asgard_parse_relident(attrelid::regclass))[1])::regnamespace::oid = ' ||
                                        item.oid_schema::text
                                WHEN catalogue.catalogue = 'pg_namespace' THEN catalogue.prefixe || 'name = ' ||
                                    quote_literal(item.nom_schema)
                                ELSE catalogue.prefixe || 'namespace = ' || item.oid_schema::text END ||
                            CASE WHEN catalogue.attrib_genre IS NOT NULL
                                THEN ' AND ' || catalogue.attrib_genre || ' ~ ' || quote_literal(catalogue.valeur_genre)
                                ELSE '' END ||
                            CASE WHEN catalogue.catalogue = 'pg_type'
                                THEN ' AND NOT (pg_type.oid, ''pg_type''::regclass::oid) IN (
                                            SELECT pg_depend.objid, pg_depend.classid
                                                FROM pg_catalog.pg_depend
                                                WHERE deptype = ANY (ARRAY[''i'', ''a''])
                                            )'
                                ELSE '' END
                LOOP
                    -- incohérence propriétaire/producteur
                    IF NOT objet.objowner = item.producteur
                        AND NOT catalogue.catalogue = ANY (ARRAY['pg_default_acl', 'pg_attribute'])
                    THEN                       
                        RETURN QUERY
                            SELECT
                                item.nom_schema::text,
                                objet.objname::text,
                                catalogue.lib_obj,
                                True,
                                format('le propriétaire (%s) n''est pas le producteur désigné pour le schéma (%s)',
                                    objet.objowner, item.producteur ) ;
                    END IF ;
                
                  -- présence de privilièges par défaut
                    IF catalogue.catalogue = 'pg_default_acl'
                    THEN
                        RETURN QUERY
                            SELECT
                                item.nom_schema::text,
                                NULL::text,
                                'privilège par défaut'::text,
                                False,
                                format('%s : %s pour le %s accordé par le rôle %s',
                                    catalogue.lib_obj,
                                    privilege,
                                    CASE WHEN grantee = 0 THEN 'pseudo-rôle public'
                                        ELSE format('rôle %s', grantee::regrole) END,
                                    objet.objowner
                                    )
                                FROM aclexplode(objet.objacl) AS acl (grantor, grantee, privilege, grantable) ;
                    -- droits
                    ELSIF catalogue.droits
                    THEN
                        -- droits à examiner sur les objets d'ASGARD
                        -- si l'objet courant est un objet d'ASGARD
                        SELECT *
                            INTO asgard
                            FROM (
                                VALUES
                                    ('z_asgard', 'z_asgard', 'schéma', 'public', 'U'),
                                    ('z_asgard', 'gestion_schema_usr', 'vue', 'public', 'rawd'),
                                    ('z_asgard', 'gestion_schema_etr', 'vue', 'public', 'rawd'),
                                    ('z_asgard', 'asgardmenu_metadata', 'vue', 'public', 'r'),
                                    ('z_asgard', 'asgardmanager_metadata', 'vue', 'public', 'r'),
                                    ('z_asgard', 'gestion_schema_read_only', 'vue', 'public', 'r')
                                ) AS t (a_schema, a_objet, a_type, role, droits)
                            WHERE a_schema = item.nom_schema 
                                AND a_objet = objet.objname::text 
                                AND a_type = catalogue.lib_obj ;
                    
                        RETURN QUERY
                            WITH privileges_effectifs AS (
                                SELECT
                                    CASE WHEN grantee = 0 THEN 'public' ELSE grantee::regrole::text END AS role_cible,
                                    privilege_effectif,
                                    grantable
                                    FROM aclexplode(objet.objacl) AS acl (grantor, grantee, privilege_effectif, grantable)
                                    WHERE objet.objacl IS NOT NULL
                            ),
                            privileges_attendus AS (
                                SELECT fonction, f_role, privilege_attendu, f_critique
                                    FROM unnest(
                                        ARRAY['le propriétaire', 'le lecteur du schéma', 'l''éditeur du schéma', 'un rôle d''ASGARD', 'le pseudo-rôle public'],
                                        ARRAY[objet.objowner, item.lecteur, item.editeur, asgard.role, 'public'],
                                        -- dans le cas d'un attribut, objet.objowner ne contient pas le propriétaire mais
                                        -- le nom de la relation. l'enregistrement sera toutefois systématiquement écarté,
                                        -- puisqu'il n'y a pas de droits standards du propriétaire sur les attributs
                                        ARRAY[catalogue.drt_producteur, catalogue.drt_lecteur, catalogue.drt_editeur, asgard.droits, catalogue.drt_public],
                                        ARRAY[False, False, False, True, False]
                                    ) AS t (fonction, f_role, f_droits, f_critique),
                                        z_asgard.asgard_expend_privileges(f_droits) AS b (privilege_attendu)
                                    WHERE f_role IS NOT NULL AND f_droits IS NOT NULL
                                        AND (NOT objet.objacl IS NULL OR NOT fonction = ANY(ARRAY['le propriétaire', 'le pseudo-rôle public']))
                            )
                            SELECT
                                item.nom_schema::text,
                                objet.objname::text,
                                catalogue.lib_obj,
                                CASE WHEN privilege_effectif IS NULL OR privilege_attendu IS NULL
                                    THEN coalesce(f_critique, False) ELSE False END,
                                CASE WHEN privilege_effectif IS NULL THEN format('privilège %s manquant pour %s (%s)', privilege_attendu, fonction, f_role)
                                    WHEN privilege_attendu IS NULL THEN format('privilège %s supplémentaire pour le rôle %s%s', privilege_effectif, role_cible,
                                        CASE WHEN grantable THEN ' (avec GRANT OPTION)' ELSE '' END)
                                    WHEN grantable THEN format('le rôle %s est habilité à transmettre le privilège %s (GRANT OPTION)', role_cible, privilege_effectif)
                                    END
                                FROM privileges_effectifs FULL OUTER JOIN privileges_attendus
                                    ON privilege_effectif = privilege_attendu
                                        AND role_cible = quote_ident(f_role)
                                WHERE privilege_effectif IS NULL OR privilege_attendu IS NULL OR grantable ;
                    END IF ;
                    
                    -- le producteur du schéma d'une vue ou vue matérialisée
                    -- n'est ni producteur, ni éditeur, ni lecteur du
                    -- schéma d'une table source
                    IF catalogue.lib_obj = ANY(ARRAY['vue', 'vue matérialisée'])
                        AND NOT item.nom_schema = 'z_asgard'
                    THEN
                        RETURN QUERY
                            SELECT
                                DISTINCT
                                item.nom_schema::text,
                                objet.objname::text,
                                catalogue.lib_obj,
                                False,
                                format('le producteur du schéma de la %s (%s) n''est pas membre des groupes lecteur, éditeur ou producteur de la %s source %s',
                                    catalogue.lib_obj, item.producteur, liblg, relname)
                                FROM pg_catalog.pg_rewrite
                                    LEFT JOIN pg_catalog.pg_depend
                                        ON objid = pg_rewrite.oid
                                    LEFT JOIN pg_catalog.pg_class
                                        ON pg_class.oid = refobjid
                                    LEFT JOIN z_asgard.gestion_schema_etr
                                        ON relnamespace::regnamespace::text = quote_ident(gestion_schema_etr.nom_schema)
                                    LEFT JOIN unnest(
                                            ARRAY['table', 'table partitionnée', 'vue', 'vue matérialisée', 'table étrangère', 'séquence'],
                                            ARRAY['r', 'p', 'v', 'm', 'f', 'S']
                                            ) AS t (liblg, libcrt)
                                        ON relkind = libcrt
                                WHERE ev_class = objet.objoid
                                    AND rulename = '_RETURN'
                                    AND ev_type = '1'
                                    AND ev_enabled = 'O'
                                    AND is_instead
                                    AND classid = 'pg_rewrite'::regclass::oid
                                    AND refclassid = 'pg_class'::regclass::oid 
                                    AND deptype = 'n'
                                    AND NOT refobjid = objet.objoid 
                                    AND NOT item.nom_schema = gestion_schema_etr.nom_schema
                                    AND NOT pg_has_role(item.oid_producteur, gestion_schema_etr.oid_producteur, 'USAGE')
                                    AND (gestion_schema_etr.oid_editeur IS NULL OR NOT pg_has_role(item.oid_producteur, gestion_schema_etr.oid_editeur, 'USAGE'))
                                    AND (gestion_schema_etr.oid_lecteur IS NULL OR NOT pg_has_role(item.oid_producteur, gestion_schema_etr.oid_lecteur, 'USAGE')) ;
                    END IF ;
                END LOOP ;
            END IF ;
        END LOOP ;        
    END LOOP ;

EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                            e_hint = PG_EXCEPTION_HINT,
                            e_detl = PG_EXCEPTION_DETAIL,
                            e_errcode = RETURNED_SQLSTATE,
                            e_schema = SCHEMA_NAME ;
    
    RAISE EXCEPTION '%', z_asgard.asgard_prefixe_erreur(e_mssg, 'FDD')
        USING DETAIL = e_detl,
            HINT = e_hint,
            SCHEMA = e_schema,
            ERRCODE = e_errcode ;

END
$_$ ;

ALTER FUNCTION z_asgard_admin.asgard_diagnostic(text[])
    OWNER TO g_admin ;

COMMENT ON FUNCTION z_asgard_admin.asgard_diagnostic(text[]) IS 'ASGARD. Pour tous les schémas actifs référencés par Asgard, liste les écarts entre les droits effectifs et les droits standards.' ;


------ 3.17 - EXTRACTION DE NOMS D'OBJETS A PARTIR D'IDENTIFIANTS ------

-- Function: z_asgard.asgard_parse_relident(regclass)

CREATE OR REPLACE FUNCTION z_asgard.asgard_parse_relident(ident regclass)
    RETURNS text[]
    LANGUAGE plpgsql
    RETURNS NULL ON NULL INPUT
    AS $_$
/* Déduit un nom de schéma et un nom de relation d'un identifiant de relation. 

    Pour PG 9.6+, cette fonction fait double emploi avec la fonction parse_ident.

    Parameters
    ----------
    ident : regclass
        Un identifiant/nom de relation casté en regclass.
    
    Returns
    -------
    text[] or NULL
        Une liste de deux éléments : r[1] est le nom du schéma et 
        r[2] le nom de la relation.
        NULL s'il n'existe pas de relation d'identifiant "ident".

    Version notes
    -------------
    v1.5.0
        (m) Ajout de l'attribut RETURNS NULL ON NULL INPUT.
        (m) Les messages d'erreur émis par la fonction sont 
            désormais marqués du préfixe FPR.

*/
DECLARE
    n_schema text ;
    n_relation text ;
    e_mssg text ;
    e_detl text ;
    e_hint text ;
    e_schema text ;
    e_errcode text ;
BEGIN

    SELECT
        pg_namespace.nspname,
        pg_class.relname
        INTO n_schema, n_relation
        FROM pg_catalog.pg_class
            LEFT JOIN pg_catalog.pg_namespace
                ON pg_class.relnamespace = pg_namespace.oid
        WHERE pg_class.oid = ident ;
    IF NOT FOUND
    THEN
        RETURN NULL ;
    ELSE
        RETURN ARRAY[n_schema, n_relation] ;
    END IF ;

EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                            e_hint = PG_EXCEPTION_HINT,
                            e_detl = PG_EXCEPTION_DETAIL,
                            e_errcode = RETURNED_SQLSTATE,
                            e_schema = SCHEMA_NAME ;
    
    RAISE EXCEPTION '%', z_asgard.asgard_prefixe_erreur(e_mssg, 'FPR')
        USING DETAIL = e_detl,
            HINT = e_hint,
            SCHEMA = e_schema,
            ERRCODE = e_errcode ;

END
$_$ ;

ALTER FUNCTION z_asgard.asgard_parse_relident(regclass)
    OWNER TO g_admin_ext ;

COMMENT ON FUNCTION z_asgard.asgard_parse_relident(regclass) IS 'ASGARD. Fonction qui retourne le nom du schéma et le nom de la relation à partir d''un identifiant de relation.' ;


------ 3.18 - EXPLICITATION DES CODES DE PRIVILÈGES ------

-- Function: z_asgard.asgard_expend_privileges(text)

CREATE OR REPLACE FUNCTION z_asgard.asgard_expend_privileges(privileges_codes text)
    RETURNS TABLE(privilege text)
    LANGUAGE SQL
    IMMUTABLE
    RETURNS NULL ON NULL INPUT 
    AS $_$
/* Fonction qui explicite les privilèges correspondant
   aux codes données en argument. 
   
    Par exemple 'SELECT' et 'UPDATE' pour 'rw'. 
   
    Si un code n'est pas reconnu, il est ignoré.

    Parameters
    ----------
    privileges_codes : text
        Les codes des privilèges, concaténés sous la forme d'une
        unique chaîne de caractères.

    Returns
    -------
    table
        Une table avec un unique champ nommé "privilege".

    Version notes
    -------------
    v1.5.0
        (M) Ajout du privilège MAINTAIN/m, introduit par PostgreSQL 17.
        (m) Ajout des attributs IMMUTABLE et RETURNS NULL ON NULL INPUT.
        (m) La fonction est désormais écrite en SQL et non en PL/pgSQL.
        (d) Amélioration formelle du descriptif.

*/
        SELECT
            p.privilege
            FROM unnest(
                ARRAY['SELECT', 'INSERT', 'UPDATE', 'DELETE',
                        'TRUNCATE', 'REFERENCES', 'TRIGGER', 'USAGE',
                        'CREATE', 'EXECUTE', 'CONNECT', 'TEMPORARY',
                        'MAINTAIN'],
                ARRAY['r', 'a', 'w', 'd', 'D', 'x', 't', 'U', 'C', 'X', 'c', 'T', 'm']
                ) AS p (privilege, prvlg)
            WHERE $1 ~ prvlg
    
    $_$ ;

ALTER FUNCTION z_asgard.asgard_expend_privileges(text)
    OWNER TO g_admin_ext ;

COMMENT ON FUNCTION z_asgard.asgard_expend_privileges(text) IS 'ASGARD. Fonction qui explicite les privilèges correspondant aux codes données en argument.' ;


------ 4.19 - RECHERCHE DE LECTEURS ET EDITEURS ------

-- Function: z_asgard.asgard_cherche_lecteur(text)

CREATE OR REPLACE FUNCTION z_asgard.asgard_cherche_lecteur(
        nom_schema text,
        autorise_public boolean DEFAULT True,
        autorise_login boolean DEFAULT False,
        autorise_superuser boolean DEFAULT False
    ) 
    RETURNS text 
    LANGUAGE SQL
    RETURNS NULL ON NULL INPUT
    AS $BODY$
/* Au vu des privilèges établis, cherche le rôle le plus susceptible d''être
   qualifié de "lecteur" du schéma.

    Cette fonction renvoie, s'il existe, le rôle qui remplit les
    conditions suivantes : 
    * Ce n'est pas le propriétaire du schéma.
    * Ce n'est pas un rôle de connexion (pas d'attribut LOGIN), sauf
      si "autorise_login" vaut True.
    * Ce n'est pas un super-utilisateur (pas d'attribut SUPERUSER), sauf
      si "autorise_superuser" vaut True.
    * Il dispose du privilège USAGE sur le schéma.
    * Il ne dispose pas du privilège CREATE sur le schéma.
    * Il dispose du privilège SELECT sur strictement plus de la moitié des
      tables, tables partitionnées, vues, vues matérialisées et tables 
      étrangères du schéma.
    * Il ne dispose des privilèges UPDATE, INSERT, DELETE ou TRUNCATE
      sur aucune des tables, tables partitionnées, vues, vues matérialisées 
      et tables étrangères du schéma.
    
    Si plusieurs rôles remplissent ces conditions, la fonction renvoie celui
    qui dispose du privilège SELECT sur le plus grand nombre de tables
    ou objets assimilés. En cas d'égalité, le rôle renvoyé sera le premier
    dans l'ordre alphabétique.

    Le pseudo-rôle "public" est pris en compte, sauf si "autorise_public"
    vaut False.

    Parameters
    ----------
    nom_schema : text
        Nom du schéma.
    autorise_public : boolean, default True
        Le pseudo-rôle "public" est-il inclus dans la recherche ?
    autorise_login : boolean, default False
        Les rôles de connexion (attribut LOGIN) sont-ils inclus dans la
        recherche ?
    autorise_superuser : boolean, default False
        Les super-utilisateurs (attribut SUPERUSER) sont-ils inclus dans la
        recherche ?
    
    Returns
    -------
    text
        Le nom du rôle pouvant être qualifié de lecteur du schéma, ou NULL
        si aucun rôle ne remplit les conditions.

*/
    WITH relations AS (
        SELECT relname, relacl, relowner
            FROM pg_catalog.pg_class
            WHERE pg_class.relnamespace = quote_ident(nom_schema)::regnamespace
                AND relkind IN ('r', 'v', 'm', 'f', 'p')
    ),
    total AS (
        SELECT floor(count(*) / 2)::int AS half FROM pg_catalog.pg_class
            WHERE pg_class.relnamespace = quote_ident(nom_schema)::regnamespace
                AND relkind IN ('r', 'v', 'm', 'f', 'p')
    ),
    relprivileges AS (
        SELECT
            acl.grantee,
            count(DISTINCT relations.relname) FILTER (WHERE acl.privilege = 'SELECT') AS count_select,
            count(DISTINCT relations.relname) FILTER (WHERE acl.privilege IN ('INSERT', 'UPDATE', 'DELETE', 'TRUNCATE')) AS count_modify
            FROM relations, aclexplode(relacl) AS acl (grantor, grantee, privilege, grantable)
            GROUP BY grantee
    ),
    nspprivileges AS (
        SELECT
            acl.grantee,
            count(DISTINCT pg_namespace.nspname) FILTER (WHERE acl.privilege = 'USAGE') AS count_usage,
            count(DISTINCT pg_namespace.nspname) FILTER (WHERE acl.privilege = 'CREATE') AS count_create
            FROM pg_catalog.pg_namespace, aclexplode(nspacl) AS acl (grantor, grantee, privilege, grantable)
            WHERE pg_namespace.nspname = nom_schema AND NOT acl.grantee = pg_namespace.nspowner
            GROUP BY grantee
    )
    SELECT
        CASE WHEN nspprivileges.grantee = 0 
        THEN 
            'public' 
        ELSE 
            pg_roles.rolname::text
        END AS rolname
        FROM nspprivileges 
            INNER JOIN relprivileges USING (grantee)
            INNER JOIN total ON total.half < relprivileges.count_select
            LEFT JOIN pg_catalog.pg_roles ON pg_roles.oid = nspprivileges.grantee
                AND (autorise_login OR NOT pg_roles.rolcanlogin)
                AND (autorise_superuser OR NOT pg_roles.rolsuper)
        WHERE 
            relprivileges.count_modify = 0 
            AND nspprivileges.count_usage = 1 
            AND nspprivileges.count_create = 0
            AND (nspprivileges.grantee = 0 AND autorise_public OR pg_roles.rolname IS NOT NULL)
        ORDER BY relprivileges.count_select DESC, coalesce(pg_roles.rolname, 'public')
        LIMIT 1 ;
    $BODY$ ;

ALTER FUNCTION z_asgard.asgard_cherche_lecteur(text, boolean, boolean, boolean) OWNER TO g_admin_ext ;

COMMENT ON FUNCTION z_asgard.asgard_cherche_lecteur(text, boolean, boolean, boolean)  IS 'ASGARD. Au vu des privilèges établis, cherche le rôle le plus susceptible d''être qualifié de "lecteur" du schéma.' ;


-- Function: z_asgard.asgard_cherche_editeur(text)

CREATE OR REPLACE FUNCTION z_asgard.asgard_cherche_editeur(
        nom_schema text,
        autorise_public boolean DEFAULT True,
        autorise_login boolean DEFAULT False,
        autorise_superuser boolean DEFAULT False
    ) 
    RETURNS text 
    LANGUAGE SQL
    RETURNS NULL ON NULL INPUT
    AS $BODY$
/* Au vu des privilèges établis, cherche le rôle le plus susceptible d''être
   qualifié d'"éditeur" du schéma.

    Cette fonction renvoie, s'il existe, le rôle qui remplit les
    conditions suivantes : 
    * Ce n'est pas le propriétaire du schéma.
    * Ce n'est pas un rôle de connexion (pas d'attribut LOGIN), sauf
      si "autorise_login" vaut True.
    * Ce n'est pas un super-utilisateur (pas d'attribut SUPERUSER), sauf
      si "autorise_superuser" vaut True.
    * Il dispose du privilège USAGE sur le schéma.
    * Il ne dispose pas du privilège CREATE sur le schéma.
    * Il dispose des privilèges INSERT et/ou UPDATE sur strictement plus
      de la moitié des tables, tables partitionnées, vues, vues matérialisées 
      et tables étrangères du schéma.
    
    Si plusieurs rôles remplissent ces conditions, la fonction renvoie celui
    qui dispose des privilèges INSERT et/ou UPDATE sur le plus grand nombre 
    de tables ou objets assimilés. En cas d'égalité, le rôle renvoyé sera le
    premier dans l'ordre alphabétique.

    Le pseudo-rôle "public" est pris en compte, sauf si "autorise_public"
    vaut False.

    Parameters
    ----------
    nom_schema : text
        Nom du schéma.
    autorise_public : boolean, default True
        Le pseudo-rôle "public" est-il inclus dans la recherche ?
    autorise_login : boolean, default False
        Les rôles de connexion (attribut LOGIN) sont-ils inclus dans la
        recherche ?
    autorise_superuser : boolean, default False
        Les super-utilisateurs (attribut SUPERUSER) sont-ils inclus dans la
        recherche ?
    
    Returns
    -------
    text
        Le nom du rôle pouvant être qualifié d'éditeur du schéma, ou NULL
        si aucun rôle ne remplit les conditions.

*/
    WITH relations AS (
        SELECT relname, relacl, relowner
            FROM pg_catalog.pg_class
            WHERE pg_class.relnamespace = quote_ident(nom_schema)::regnamespace
                AND relkind IN ('r', 'v', 'm', 'f', 'p')
    ),
    total AS (
        SELECT floor(count(*) / 2)::int AS half FROM pg_catalog.pg_class
            WHERE pg_class.relnamespace = quote_ident(nom_schema)::regnamespace
                AND relkind IN ('r', 'v', 'm', 'f', 'p')
    ),
    relprivileges AS (
        SELECT
            acl.grantee,
            count(DISTINCT relations.relname) FILTER (WHERE acl.privilege IN ('INSERT', 'UPDATE')) AS count_edit
            FROM relations, aclexplode(relacl) AS acl (grantor, grantee, privilege, grantable)
            GROUP BY grantee
    ),
    nspprivileges AS (
        SELECT
            acl.grantee,
            count(DISTINCT pg_namespace.nspname) FILTER (WHERE acl.privilege = 'USAGE') AS count_usage,
            count(DISTINCT pg_namespace.nspname) FILTER (WHERE acl.privilege = 'CREATE') AS count_create
            FROM pg_catalog.pg_namespace, aclexplode(nspacl) AS acl (grantor, grantee, privilege, grantable)
            WHERE pg_namespace.nspname = nom_schema AND NOT acl.grantee = pg_namespace.nspowner
            GROUP BY grantee
    )
    SELECT
        CASE WHEN nspprivileges.grantee = 0 
        THEN 
            'public' 
        ELSE 
            pg_roles.rolname::text
        END AS rolname
        FROM nspprivileges 
            INNER JOIN relprivileges USING (grantee)
            INNER JOIN total ON total.half < relprivileges.count_edit
            LEFT JOIN pg_catalog.pg_roles ON pg_roles.oid = nspprivileges.grantee
                AND (autorise_login OR NOT pg_roles.rolcanlogin)
                AND (autorise_superuser OR NOT pg_roles.rolsuper)
        WHERE nspprivileges.count_usage = 1 
            AND nspprivileges.count_create = 0
            AND (nspprivileges.grantee = 0 AND autorise_public OR pg_roles.rolname IS NOT NULL)
        ORDER BY relprivileges.count_edit DESC, coalesce(pg_roles.rolname, 'public')
        LIMIT 1 ;
    $BODY$ ;

ALTER FUNCTION z_asgard.asgard_cherche_editeur(text, boolean, boolean, boolean) OWNER TO g_admin_ext ;

COMMENT ON FUNCTION z_asgard.asgard_cherche_editeur(text, boolean, boolean, boolean)  IS 'ASGARD. Au vu des privilèges établis, cherche le rôle le plus susceptible d''être qualifié d''"éditeur" du schéma.' ;


-- Function: z_asgard_admin.asgard_restaure_editeurs_lecteurs(text, boolean, boolean, boolean, boolean)

CREATE OR REPLACE FUNCTION z_asgard_admin.asgard_restaure_editeurs_lecteurs(
    nom_schema text DEFAULT NULL,
    preserve boolean DEFAULT True,
    autorise_public boolean DEFAULT True,
    autorise_login boolean DEFAULT False,
    autorise_superuser boolean DEFAULT False
)
    RETURNS text
    LANGUAGE plpgsql
    AS $_$
/* Recalcule les éditeurs et lecteurs renseignés dans la table de gestion en fonction 
   des droits effectifs.

    Cette fonction s'appuie sur "z_asgard"."asgard_cherche_editeur" et 
    "z_asgard"."asgard_cherche_lecteur" pour recalculer les lecteurs et éditeurs
    de la table de gestion en fonction des privilèges effectifs sur les
    objets de la base. Au contraire d'un simple UPDATE des champs "editeur" et 
    "lecteur" de la table, qui confère une fonction au rôle spécifié et
    pourra donc avoir pour effet de modifier les privilèges dont il dispose selon
    ceux qui sont prévus pour ladite fonction (et, le cas échéant, de retirer lesdits
    privilèges au rôle qui occupait auparavant la fonction), 
    "asgard_restaure_editeurs_lecteurs" n'altère en aucune façon les droits de la base.

    Parameters
    ----------
    nom_schema : text, optional
        Si renseigné, les champs "lecteur" et "editeur" ne seront recalculés
        que pour le rôle considéré. Sinon, ils seront mis à jour pour tous les
        schémas actifs de la table.
    preserve : boolean, default True
        Si True, la fonction ne modifiera pas les lecteurs et éditeurs 
        déjà renseignés dans la table de gestion. Elle en ajoutera
        simplement là où il n'y en avait pas, sous réserve que les fonctions de
        recherche aient renvoyé un résultat. À noter que si "preserve" vaut False,
        la fonction aura aussi pour effet d'effacer les éditeurs et lecteurs
        sans en renseigner de nouveaux quand les fonctions de recherche
        n'identifient pas de rôles satisfaisant aux conditions.
    autorise_public : boolean, default False
        Passé en argument aux fonctions "asgard_cherche_editeur"
        et "asgard_cherche_lecteur". Cf. définition de ces fonctions pour plus 
        de détails.
    autorise_login : boolean, default False
        Passé en argument aux fonctions "asgard_cherche_editeur"
        et "asgard_cherche_lecteur". Cf. définition de ces fonctions pour plus 
        de détails.
    autorise_superuser : boolean, default False
        Passé en argument aux fonctions "asgard_cherche_editeur"
        et "asgard_cherche_lecteur". Cf. définition de ces fonctions pour plus 
        de détails.

    Returns
    -------
    text
        '__ RESTAURATION DES LECTEURS ET EDITEURS REUSSIE.'

    Version notes
    -------------
    v1.5.0
        (m) Amélioration de la gestion des messages d'erreur.
            La fonction utilise désormais le code d'erreur FRL 
            au lieu de FRE.

*/
DECLARE
    rec record ;
    e_mssg text ;
    e_hint text ;
    e_detl text ;
    e_schema text ;
    e_errcode text ;
BEGIN

    ALTER TABLE z_asgard_admin.gestion_schema
        DISABLE TRIGGER asgard_on_modify_gestion_schema_before,
        DISABLE TRIGGER asgard_on_modify_gestion_schema_after ;

    FOR rec IN (
        SELECT 
            gestion_schema.nom_schema,
            gestion_schema.editeur AS old_editeur,
            z_asgard.asgard_cherche_editeur(
                nom_schema := gestion_schema.nom_schema,
                autorise_public := asgard_restaure_editeurs_lecteurs.autorise_public,
                autorise_login := asgard_restaure_editeurs_lecteurs.autorise_login,
                autorise_superuser := asgard_restaure_editeurs_lecteurs.autorise_superuser
            ) AS new_editeur,
            gestion_schema.lecteur AS old_lecteur,
            z_asgard.asgard_cherche_lecteur(
                nom_schema := gestion_schema.nom_schema,
                autorise_public := asgard_restaure_editeurs_lecteurs.autorise_public,
                autorise_login := asgard_restaure_editeurs_lecteurs.autorise_login,
                autorise_superuser := asgard_restaure_editeurs_lecteurs.autorise_superuser
            ) AS new_lecteur
            FROM z_asgard_admin.gestion_schema
            WHERE creation AND 
                (
                    asgard_restaure_editeurs_lecteurs.nom_schema IS NULL 
                    OR gestion_schema.nom_schema = asgard_restaure_editeurs_lecteurs.nom_schema
                )
    )
    LOOP

        -- éditeur
        IF (rec.old_editeur IS NULL OR NOT asgard_restaure_editeurs_lecteurs.preserve) 
            AND coalesce(rec.old_editeur, '') != coalesce(rec.new_editeur, '')
        THEN

            IF rec.new_editeur = 'public'
            THEN

                UPDATE z_asgard_admin.gestion_schema
                    SET editeur = 'public',
                        oid_editeur = 0
                    WHERE gestion_schema.nom_schema = rec.nom_schema ;
            
            ELSIF rec.new_editeur IS NULL
            THEN 

                 UPDATE z_asgard_admin.gestion_schema
                    SET editeur = NULL,
                        oid_editeur = NULL
                        WHERE gestion_schema.nom_schema = rec.nom_schema ;
            
            ELSE

                UPDATE z_asgard_admin.gestion_schema
                    SET editeur = rec.new_editeur,
                        oid_editeur = quote_ident(rec.new_editeur)::regrole::oid
                    WHERE gestion_schema.nom_schema = rec.nom_schema ;
            
            END IF ;        

            RAISE NOTICE '%', format(
                'Restauration de l''éditeur du schéma "%s" dans la table de gestion. Avant : %s ; après : %s.',
                rec.nom_schema,
                coalesce(rec.old_editeur, 'NULL'),
                coalesce(rec.new_editeur, 'NULL')
            ) ;
        
        END IF ;

        -- lecteur
        IF (rec.old_lecteur IS NULL OR NOT asgard_restaure_editeurs_lecteurs.preserve) 
            AND coalesce(rec.old_lecteur, '') != coalesce(rec.new_lecteur, '')
        THEN

            IF rec.new_lecteur = 'public'
            THEN

                UPDATE z_asgard_admin.gestion_schema
                    SET lecteur = 'public',
                        oid_lecteur = 0
                    WHERE gestion_schema.nom_schema = rec.nom_schema ;

            ELSIF rec.new_lecteur IS NULL
            THEN 

                 UPDATE z_asgard_admin.gestion_schema
                    SET lecteur = NULL,
                        oid_lecteur = NULL
                        WHERE gestion_schema.nom_schema = rec.nom_schema ;
            
            ELSE

                UPDATE z_asgard_admin.gestion_schema
                    SET lecteur = rec.new_lecteur,
                        oid_lecteur = quote_ident(rec.new_lecteur)::regrole::oid
                    WHERE gestion_schema.nom_schema = rec.nom_schema ;
            
            END IF ;        

            RAISE NOTICE '%', format(
                'Restauration du lecteur du schéma "%s" dans la table de gestion. Avant : %s ; après : %s.',
                rec.nom_schema,
                coalesce(rec.old_lecteur, 'NULL'),
                coalesce(rec.new_lecteur, 'NULL')
            ) ;
        
        END IF ;

    END LOOP ;

    ALTER TABLE z_asgard_admin.gestion_schema
        ENABLE TRIGGER asgard_on_modify_gestion_schema_before,
        ENABLE TRIGGER asgard_on_modify_gestion_schema_after ;

    RETURN '__ RESTAURATION DES LECTEURS ET EDITEURS REUSSIE.' ;

EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                            e_hint = PG_EXCEPTION_HINT,
                            e_detl = PG_EXCEPTION_DETAIL,
                            e_errcode = RETURNED_SQLSTATE,
                            e_schema = SCHEMA_NAME ;
    
    RAISE EXCEPTION '%', z_asgard.asgard_prefixe_erreur(e_mssg, 'FRL')
        USING DETAIL = e_detl,
            HINT = e_hint,
            SCHEMA = e_schema,
            ERRCODE = e_errcode ;

END
$_$;

ALTER FUNCTION z_asgard_admin.asgard_restaure_editeurs_lecteurs(text, boolean, boolean, boolean, boolean)
    OWNER TO g_admin ;

COMMENT ON FUNCTION z_asgard_admin.asgard_restaure_editeurs_lecteurs(text, boolean, boolean, boolean, boolean) IS 'ASGARD. Recalcule les éditeurs et lecteurs renseignés dans la table de gestion en fonction des droits effectifs.' ;


------ 3.20 - RECHERCHE DU MEILLEUR RÔLE POUR REALISER UNE OPERATION ------

-- Function: z_asgard.asgard_complete_heritage(text)

CREATE OR REPLACE FUNCTION z_asgard.asgard_complete_heritage(
    role_cible text
)
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
/* Complète la chaîne de permissions permettant à l'utilisateur courant
   d'hériter du rôle cible.

    Si l'utilisateur courant est membre du rôle cible mais n'hérite pas 
    de ses droits et/ou n'est pas habilité à endosser ce rôle, la 
    fonction tente de compléter la chaîne de permissions en ajoutant
    les options SET et INHERIT à des rôles qui disposeraient
    seulement de l'option ADMIN.

    Lorsque plusieurs chaînes de permissions sont possibles, la fonction
    tente d'en trouver une qui puisse être résolue.

    Il est possible d'empêcher cette fonction d'accorder des options
    supplémentaires en ajoutant le paramètre sans_explicitation_set_inherit_option
    à la table de configuration d'Asgard.

    Parameters
    ----------
    role_cible : text
        Le nom du rôle cible.

    Returns
    -------
    boolean
        True si, à l'issue de l'exécution de la fonction, l'utilisateur
        courant hérite des droits du rôle cible et peut l'endosser.

    Version notes
    -------------
    v1.5.0
        (C) Création.

*/
DECLARE
    membre record ;
    commande text ;
    e_mssg text ;
    e_hint text ;
    e_detl text ;
    e_errcode text ;
BEGIN

    -- Sous les versions de PostgreSQL antérieures à la 16, il n'y
    -- pas d'options SET et INHERIT sur les relations. Soit il
    -- existe une chaîne de relations dont aucun rôle n'a l'attribut 
    -- NOINHERIT, soit non et la fonction ne pourra rien compléter.
    IF current_setting('server_version_num')::int < 160000
    THEN
        RETURN pg_has_role(role_cible, 'USAGE') ;
    END IF ;

    -- Cas d'une chaîne déjà valide.
    IF pg_has_role(role_cible, 'SET') 
        AND pg_has_role(role_cible, 'USAGE')
    THEN
        RETURN True ;
    END IF ;

    -- Si la configuration d'Asgard n'autorise pas à expliciter les
    -- permissions des rôles administrateurs, on renvoie False,
    -- même si le rôle avait l'une des deux options
    IF z_asgard.asgard_parametre('sans_explicitation_set_inherit_option')
    THEN
        RETURN False ;
    END IF ;

    -- Sinon, boucle sur les membres du rôle cible, à la recherche
    -- d'une chaîne qui pourrait être complétée.
    -- Ne sont considérées que les relations telles que :
    -- - Le rôle membre a l'attribut INHERIT (par défaut, il hérite
    --   des privilèges des rôles dont il est membre).
    -- - Soit le rôle est membre du rôle cible avec l'option ADMIN, 
    --   soit il en est membre avec les option INHERIT et SET.
    -- - La relation s'inscrit bien dans une chaîne entre le rôle
    --   courant et le rôle cible.
    FOR membre IN (
        SELECT
            enfant.rolname,
            pg_auth_members.inherit_option,
            pg_auth_members.set_option
            FROM pg_catalog.pg_auth_members
                INNER JOIN pg_catalog.pg_roles AS parent 
                    ON parent.oid = pg_auth_members.roleid
                INNER JOIN pg_catalog.pg_roles AS enfant 
                    ON enfant.oid = pg_auth_members.member
            WHERE parent.rolname = role_cible
                AND enfant.rolinherit
                AND (
                    pg_auth_members.admin_option
                    OR pg_auth_members.set_option AND pg_auth_members.inherit_option
                )
                AND pg_has_role(enfant.rolname, 'MEMBER')
            ORDER BY enfant.rolname
    )
    LOOP

        -- Résolution du début de la chaîne, si c'est possible.
        -- À défaut, on passe au rôle suivant, pour tenter une autre chaîne.
        IF NOT z_asgard.asgard_complete_heritage(membre.rolname)
        THEN
            CONTINUE ;
        END IF ;

        -- Ajout des options manquantes, le cas échéant.
        -- Le fait que le début de la chaîne ait été complété assure que le rôle
        -- courant hérite du rôle membre et peut donc utiliser son option ADMIN
        -- sur role_cible pour lancer des commandes GRANT.
        IF NOT membre.inherit_option AND NOT membre.set_option
        THEN
            EXECUTE format(
                'GRANT %I TO %I WITH INHERIT True, SET True GRANTED BY %I', 
                role_cible, membre.rolname, membre.rolname
            ) ;
            RAISE NOTICE '%', format(
                '... Octroi au rôle %I, membre de %I avec l''option ADMIN, de l''accès aux privilèges de ce rôle (options SET et INHERIT).', 
                membre.rolname, 
                role_cible
            ) ;
        ELSIF NOT membre.inherit_option 
        THEN
            EXECUTE format(
                'GRANT %I TO %I WITH INHERIT True GRANTED BY %I', 
                role_cible, membre.rolname, membre.rolname
            ) ;
            RAISE NOTICE '%', format(
                '... Octroi au rôle %I, membre de %I avec l''option ADMIN, de l''accès aux privilèges de ce rôle (option INHERIT).', 
                membre.rolname, 
                role_cible
            ) ;
        ELSIF NOT membre.set_option
        THEN
            EXECUTE format(
                'GRANT %I TO %I WITH SET True GRANTED BY %I', 
                role_cible, membre.rolname, membre.rolname
            ) ;
            RAISE NOTICE '%', format(
                '... Octroi au rôle %I, membre de %I avec l''option ADMIN, de l''accès aux privilèges de ce rôle (option SET).', 
                membre.rolname, 
                role_cible
            ) ;
        END IF ;

        RETURN True ;

    END LOOP ;

    RETURN False ;

EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                            e_hint = PG_EXCEPTION_HINT,
                            e_detl = PG_EXCEPTION_DETAIL,
                            e_errcode = RETURNED_SQLSTATE ;
    
    RAISE EXCEPTION '%', z_asgard.asgard_prefixe_erreur(e_mssg, 'FCH')
        USING DETAIL = e_detl,
            HINT = e_hint,
            ERRCODE = e_errcode ;

END
$_$ ;


ALTER FUNCTION z_asgard.asgard_complete_heritage(text)
    OWNER TO g_admin_ext ;

COMMENT ON FUNCTION z_asgard.asgard_complete_heritage(text) IS 'ASGARD. Complète la chaîne de permissions permettant à l''utilisateur courant d''hériter du rôle cible.' ;


-- Function: z_asgard.asgard_grant_producteur_to_g_admin(text, boolean)

CREATE OR REPLACE FUNCTION z_asgard.asgard_grant_producteur_to_g_admin(
    producteur text,
    permissif boolean DEFAULT False
)
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
/* Rend g_admin membre du rôle producteur cible.

    Cette fonction doit être exécutée par un rôle habilité à 
    conférer des permissions sur "producteur".

    Elle rend g_admin membre avec l'option ADMIN du rôle
    propriétaire du schéma considéré, sauf si : 
    - Ce rôle est g_admin lui-même.
    - g_admin est déjà membre de ce rôle avec l'option ADMIN.
    - Ce rôle est un super-utilisateur.
    - Ce rôle est membre de g_admin, directement ou non.

    Les deux derniers cas correspondent à des situations où g_admin ne
    pourra pas intervenir sur le schéma. Le dernier suscitera une erreur,
    sauf si la table de configuration d'Asgard contient la clé
    'autorise_producteur_membre_g_admin' qui l'autorise.

    Le paramètre 'g_admin_sans_permission_producteurs' empêche la fonction
    de conférer des permissions à g_admin sur les producteurs des schémas.
    Avec 'g_admin_sans_admin_option_producteurs', elle continue à conférer
    des permissions, mais sans l'option ADMIN.

    Cette fonction veille également à ce que les producteurs de schémas ne
    soient pas des rôles de connexion, sauf si la table de configuration
    d'Asgard contient la clé 'autorise_producteur_connexion' qui le permet.

    Parameters
    ----------
    producteur : text
        Le nom du rôle cible, présumé être un rôle producteur de schéma
        au sens d'Asgard.
    permissif : boolean, default False
        Si False, et sauf paramètrage contraire dans la table de configuration
        la fonction émet des erreurs lorsque le rôle cible est un rôle de
        connexion ou un rôle lui-même membre de g_admin. Si True, elle
        se contente de renvoyer False pour signifier qu'elle n'a pas rendu
        g_admin membre de ces rôles.

    Returns
    -------
    boolean
        True si la fonction a effectivement exécuté une commande
        rendant g_admin membre du rôle cible.

    Raises
    ------
    invalid_parameter_value
        FGP1. Si le rôle "producteur" n'existe pas.
    invalid_grant_operation
        FGP2. Sauf à ce que la configuration d'Asgard l'autorise ou que "permissif"
        vaille True, quand le producteur du schéma est un rôle de connexion non 
        super-utilisateur.
        FGP3. Sauf à ce que la configuration d'Asgard l'autorise ou que "permissif"
        vaille True, quand le producteur du schéma est un non super-utilisateur 
        membre de g_admin, y compris par héritage.

    Version notes
    -------------
    v1.5.0
        (C) Création.

*/
DECLARE
    e_mssg text ;
    e_hint text ;
    e_detl text ;
    e_errcode text ;
    prod record ;
BEGIN

    -- si le paramétrage indique qu'aucune permission ne doit être conférée
    -- à g_admin, on arrête là
    IF z_asgard.asgard_parametre('g_admin_sans_permission_producteurs')
    THEN
        RETURN False ;
    END IF ;

    SELECT 
        pg_roles.oid, 
        pg_roles.rolcanlogin, 
        pg_roles.rolsuper
        INTO prod
        FROM pg_catalog.pg_roles
        WHERE pg_roles.rolname = producteur ;

    IF NOT FOUND 
    THEN
        RAISE EXCEPTION 'FGP1. Le rôle % n''existe pas.', producteur 
            USING ERRCODE = 'invalid_parameter_value' ;
    END IF ;

    -- sauf paramétrage contraire, si le producteur est un rôle de connexion,
    -- on retourne une erreur
    IF NOT z_asgard.asgard_parametre('autorise_producteur_connexion')
        AND prod.rolcanlogin AND NOT prod.rolsuper
    THEN
        IF NOT permissif 
        THEN
            RAISE EXCEPTION 'FGP2. Opération interdite (rôle %). Le producteur/propriétaire d''un schéma ne peut pas être un rôle de connexion (rôle non super-utilisateur disposant de l''attribut LOGIN).', producteur
                USING ERRCODE = 'invalid_grant_operation' ;
        ELSE
            RETURN False ;
        END IF ;
    END IF ;

    -- on ne considère pas le cas où le producteur est un super-utilisateur
    IF prod.rolsuper
    THEN
        RETURN False ;
    END IF ;

    -- ni le cas où g_admin est déjà directement membre du producteur,
    -- ou quand le producteur est g_admin lui-même
    IF producteur = 'g_admin' OR 'g_admin' IN (
        SELECT pg_auth_members.member::regrole::text
            FROM pg_catalog.pg_auth_members
            WHERE pg_auth_members.roleid = prod.oid
                AND (
                    pg_auth_members.admin_option 
                    OR z_asgard.asgard_parametre('g_admin_sans_admin_option_producteurs')
                )
    )
    THEN
        RETURN False ;
    END IF ;

    -- si le producteur est membre de g_admin, on retourne une erreur, sauf
    -- paramétrage contraire
    IF pg_has_role(producteur, 'g_admin', 'MEMBER') 
    THEN
        IF NOT permissif 
            AND NOT z_asgard.asgard_parametre('autorise_producteur_membre_g_admin')
        THEN
            RAISE EXCEPTION 'FGP3. Opération interdite (rôle %). Les rôles producteurs/propriétaires de schémas non super-utilisateurs ne peuvent pas être membres de g_admin, y compris par héritage.', producteur
                USING HINT = 'Pourquoi ne pas désigner directement de g_admin comme producteur du schéma ?',
                    ERRCODE = 'invalid_grant_operation' ;
        ELSE
            RETURN False ;
        END IF ;
    END IF ;
    
    IF z_asgard.asgard_parametre('g_admin_sans_admin_option_producteurs')
    THEN
        EXECUTE format('GRANT %I TO g_admin', producteur) ;
        RAISE NOTICE '... Permission accordée à g_admin sur le rôle %.', producteur ;
    ELSE
        EXECUTE format('GRANT %I TO g_admin WITH ADMIN OPTION', producteur) ;
        RAISE NOTICE '... Permission accordée à g_admin sur le rôle % avec l''option ADMIN.', producteur ;
    END IF ;

    RETURN True ;

EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                            e_hint = PG_EXCEPTION_HINT,
                            e_detl = PG_EXCEPTION_DETAIL,
                            e_errcode = RETURNED_SQLSTATE ;
    
    RAISE EXCEPTION '%', z_asgard.asgard_prefixe_erreur(e_mssg, 'FGP')
        USING DETAIL = e_detl,
            HINT = e_hint,
            ERRCODE = e_errcode ;

END
$_$ ;

ALTER FUNCTION z_asgard.asgard_grant_producteur_to_g_admin(text, boolean)
    OWNER TO g_admin_ext ;

COMMENT ON FUNCTION z_asgard.asgard_grant_producteur_to_g_admin(text, boolean) IS 'ASGARD. Rend g_admin membre du rôle producteur cible.' ;


-- Function: z_asgard.asgard_heritage_via_g_admin(text)

CREATE OR REPLACE FUNCTION z_asgard.asgard_heritage_via_g_admin(
    producteur text
)
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
/* Si pertinent, rend g_admin membre du rôle cible pour compléter la 
   chaîne de permissions de l'utilisateur courant.

    La fonction renvoie toujours True, et n'a aucun autre effet, dès
    lors que l'utilisateur est membre de g_admin et que ce dernier
    hérite déjà du rôle cible.

    Sinon :
    - Sous PostgreSQL 16+, la fonction renvoie toujours False.
    - Si l'utilisateur n'est pas membre de g_admin, la fonction
      renvoie toujours False.
    - Sinon, la fonction tente de rendre g_admin membre du rôle cible, 
      en respectant la configuration d'Asgard en la matière. Elle 
      renvoie True si elle a réussi, False si elle a échoué.

    Parameters
    ----------
    producteur : text
        Le nom du rôle cible, présumé être un rôle producteur de schéma
        au sens d'Asgard.

    Returns
    -------
    boolean
        True si, à l'issue de l'exécution de la fonction, l'utilisateur
        courant peut hériter des droits du rôle cible en endossant
        le rôle g_admin.

    Version notes
    -------------
    v1.5.0
        (C) Création.

*/
DECLARE
    utilisateur text := current_user ;
    executant text ;
    resultat boolean ;
    e_mssg text ;
    e_hint text ;
    e_detl text ;
    e_errcode text ;
BEGIN

    -- si le rôle courant n'est même pas membre de
    -- g_admin, on abandonne
    IF NOT pg_has_role('g_admin', 'MEMBER')
    THEN
        RETURN False ;
    -- si g_admin hérite déjà du rôle cible, 
    -- c'est déjà bon
    ELSIF pg_has_role('g_admin', producteur, 'USAGE')
    THEN
        RETURN True ;
    -- si le rôle cible est un super-utilisateur,
    -- on abandonne
    ELSIF (
        SELECT pg_roles.rolsuper 
            FROM pg_catalog.pg_roles 
            WHERE pg_roles.rolname = producteur
    )
    THEN
        RETURN False ;
    -- sous PG16+, g_admin ne peut pas s'auto-conférer des
    -- permissions en se prévalant de son attribut CREATEROLE,
    -- plutôt que la présente fonction, on utilisera 
    -- z_asgard.asgard_complete_heritage pour compléter si 
    -- possible la chaîne de permissions
    ELSIF current_setting('server_version_num')::int >= 160000
    THEN
        RETURN False ;
    END IF ;

    -- choix d'un rôle habilité à exécuter les commandes (sinon
    -- asgard_cherche_executant émet une erreur)
    -- le rôle courant étant membre de g_admin, qui est censé
    -- avoir CREATEROLE, asgard_cherche_executant devrait toujours 
    -- trouver un rôle utilisable
    executant := z_asgard.asgard_cherche_executant(
        'GRANT ROLE',
        new_producteur := producteur
    ) ;
    EXECUTE format('SET ROLE %I', executant) ;
    SELECT z_asgard.asgard_grant_producteur_to_g_admin(producteur, permissif := True) INTO resultat ;
    EXECUTE format('SET ROLE %I', utilisateur) ;

    IF resultat
    THEN
        -- on ne renvoie pas directement resultat pour prendre
        -- en compte le cas invraisemblable et indésirable où
        -- g_admin aurait l'attribut NOINHERIT.
        RETURN pg_has_role('g_admin', producteur, 'USAGE') ;
    ELSE
        RETURN False ;
    END IF ;    

EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                            e_hint = PG_EXCEPTION_HINT,
                            e_detl = PG_EXCEPTION_DETAIL,
                            e_errcode = RETURNED_SQLSTATE ;
    
    RAISE EXCEPTION '%', z_asgard.asgard_prefixe_erreur(e_mssg, 'FHA')
        USING DETAIL = e_detl,
            HINT = e_hint,
            ERRCODE = e_errcode ;

END
$_$ ;

ALTER FUNCTION z_asgard.asgard_heritage_via_g_admin(text)
    OWNER TO g_admin_ext ;

COMMENT ON FUNCTION z_asgard.asgard_heritage_via_g_admin(text) IS 'ASGARD. Si pertinent, rend g_admin membre du rôle cible pour compléter la chaîne de permissions de l''utilisateur courant.' ;


-- Function: z_asgard.asgard_cherche_executant(text, text, text)

CREATE OR REPLACE FUNCTION z_asgard.asgard_cherche_executant(
        operation text,
        new_producteur text DEFAULT NULL,
        old_producteur text DEFAULT NULL
) 
    RETURNS text 
    LANGUAGE plpgsql
    AS $_$
/* Recherche le meilleur rôle à faire endosser à l'utilisateur courant pour
   exécuter une commande d'administration.

    Si l'utilisateur courant remplit toutes les conditions, il sera
    toujours privilégié.

    Sous PostgreSQL 16+, cette fonction est susceptible de donner les options
    SET et INHERIT à des rôles qui étaient membres d'autres rôles avec
    l'option ADMIN, afin de rendre possibles des opérations qui ne l'auraient
    pas été autrement.

    Sous les versions antérieures à PostgreSQL 16, la fonction est susceptible
    de rendre le rôle "g_admin" membre des rôles "new_producteur" et
    "old_producteur", toujours afin de rendre possibles des opérations qui ne 
    l'auraient pas été autrement.

    Selon la nature de l'opération considérée, spécifiée par le paramètre
    "operation", renseigner le paramètre "new_producteur" et/ou "old_producteur"
    peut être requis. Si le paramètre n'est pas fourni ou si le rôle n'existe
    pas, la fonction renverra une erreur. Cf. description du paramètre
    "operation" pour plus de détails.

    Cette fonction s'utilisera généralement comme suit :
     
        utilisateur := current_user ;
        -- choix d'un rôle habilité à exécuter les commandes (sinon
        -- asgard_cherche_executant émet une erreur)
        executant := z_asgard.asgard_cherche_executant('CODE OPERATION') ;
        EXECUTE format('SET ROLE %I', executant) ;
        -- [...] commandes correspondant à l'opération à réaliser
        EXECUTE format('SET ROLE %I', utilisateur) ;

    Parameters
    ----------
    operation : {
            'CREATE ROLE', 'GRANT ROLE', 'CREATE SCHEMA', 'ALTER SCHEMA RENAME', 
            'ALTER SCHEMA OWNER', 'DROP SCHEMA', 'ALTER OBJECT OWNER',
            'ALTER OBJECT SCHEMA', 'PRIVILEGES', 'ALTER DEFAULT PRIVILEGES',
            'POLICIES', 'MODIFY GESTION SCHEMA'
        }
        Le type d'opération à réaliser : 
        - 'CREATE ROLE' pour la création d'un ou plusieurs rôles.
        - 'GRANT ROLE' pour rendre un rôle membre d'un autre. Le
           paramètre "new_producteur" doit spécifier le nom du rôle
           sur lequel on souhaite accorder des permissions.
        - 'CREATE SCHEMA' pour la création d'un schéma. Le paramètre
          "new_producteur" doit spécifier le nom du nouveau producteur
          (propriétaire) du schéma.
        - 'ALTER SCHEMA RENAME' pour la modification du nom du schéma.
          "new_producteur" doit spécifier le nom du producteur
          (propriétaire du schéma).
        - 'ALTER SCHEMA OWNER' pour la modification du producteur 
          (propriétaire) du schéma. "old_producteur" doit spécifier le
          nom de l'ancien producteur, "new_producteur" celui du nouveau.
        - 'DROP SCHEMA' pour la suppression d'un schéma. "old_producteur"
          doit spécifier le nom du rôle qui était producteur du schéma.
        - 'ALTER OBJECT OWNER' pour la modification du propriétaire 
          d'objets inclus dans un schéma référencé par Asgard.
          "new_producteur" doit spécifier le nom du nouveau propriétaire,
          qui doit impérativement être le producteur du schéma de l'objet,
          "old_producteur" celui de l'ancien.
        - 'ALTER OBJECT SCHEMA' pour le changement de schéma d'un objet
          (entre deux schémas référencés par Asgard). "new_producteur"
          doit spécifier le nom du producteur du nouveau schéma, 
          "old_producteur" celui de l'ancien.
        - 'PRIVILEGES' pour la modification des privilèges sur un 
          schéma référencé par Asgard et ses objets. "new_producteur"
          doit spécifier le nom du producteur du schéma. Les attributs
          "GRANT OPTION" ne sont pas pris en compte, la fonction ne considère
          que les rôles qui héritent des droits du producteur du schéma.
        - 'ALTER DEFAULT PRIVILEGES' pour la modification des privilèges
          par défaut dans un schéma. "new_producteur" est le nom du 
          rôle pour lequel les privilèges par défaut sont définis (les
          privilèges seront appliqués aux objets qu'il créera).
        - 'POLICIES' pour toutes les opérations relatives aux politiques de
          sécurité niveau ligne (row level security policy), incluant leur
          activation sur une table. "new_producteur" est le nom du 
          propriétaire de la table.
        - 'MODIFY GESTION SCHEMA' pour la mise à jour ou suppression d'un 
          enregistrement de la table de gestion.
          "new_producteur" est le nom du producteur actuellement référencé
          dans la table de gestion pour le schéma.
          Le rôle renvoyé par la fonction est assuré de voir l'enregistrement
          correspondant au schéma dans les vues z_asgard.gestion_schema_etr
          et z_asgard.gestion_schema_usr.
          Ce résultat est valide que le schéma soit actif ou non. La fonction
          tolère que le rôle "new_producteur" n'existe pas, et cherche alors
          un rôle héritant de g_admin.
    new_producteur : text, optional
        Généralement le nom du rôle producteur du schéma à l'issue de 
        l'opération. La description du type d'opération (cf. ci-dessus)
        précise si le paramètre doit être spécifié et quelle information
        il doit contenir.
    old_producteur : text, optional
        Généralement le nom du rôle qui était producteur du schéma avant 
        l'opération. La description du type d'opération (cf. ci-dessus)
        précise si le paramètre doit être spécifié et quelle information
        il doit contenir.
    
    Returns
    -------
    text
        Le nom du rôle à utiliser.

    Raises
    ------
    insufficient_privilege
        FRE1 à FRE13. Quand il n'a pas été possible de trouver un rôle remplissant
        toutes les conditions. Le code d'erreur (FREx) varie selon 
        l'opération et le message d'erreur détaille les conditions
        non remplies.
    invalid_parameter_value
        FRE80. Si le rôle spécifié par le paramètre "new_producteur" 
        n'existe pas.
        FRE81. Si le rôle spécifié par le paramètre "old_producteur" 
        n'existe pas.
        FRE90. Quand la valeur du paramètre "operation" n'est pas
        reconnue.
    null_value_not_allowed
        FRE50. Si le paramètre "new_producteur" n'a pas été renseigné 
        alors qu'il est requis.
        FRE51. Si le paramètre "old_producteur" n'a pas été renseigné 
        alors qu'il est requis.

    Version notes
    -------------
    v1.5.0
        (C) Création.

*/
DECLARE
    executant text ;
    candidat record ;
    no_new_producteur boolean := False ;
    e_mssg text ;
    e_hint text ;
    e_detl text ;
    e_errcode text ;
BEGIN

    ------- Contrôles préalables ------

    IF NOT operation IN ('CREATE ROLE', 'DROP SCHEMA')
    THEN

        -- "new_producteur" n'est pas renseigné
        IF new_producteur IS NULL
        THEN

            RAISE EXCEPTION 'FRE50. Le paramètre "new_producteur" doit être spécifié.'
                USING ERRCODE = 'null_value_not_allowed',
                    DETAIL = format('Opération : %s.', operation) ;

        -- le rôle "new_producteur" n'existe pas
        ELSIF NOT new_producteur IN (
                SELECT pg_roles.rolname
                    FROM pg_catalog.pg_roles
            )
        THEN
            -- l'opération MODIFY GESTION SCHEMA est actuellement la seule
            -- à tolérer un rôle qui n'existe pas
            IF operation = 'MODIFY GESTION SCHEMA'
            THEN
                no_new_producteur := True ;
            ELSE
                RAISE EXCEPTION 'FRE80. Le rôle "%" n''existe pas.', new_producteur
                    USING ERRCODE = 'invalid_parameter_value',
                        DETAIL = format('Opération : %s.', operation) ;

            END IF ;        
        END IF ;
    END IF ;

    IF operation IN (
        'ALTER SCHEMA OWNER', 'DROP SCHEMA', 'ALTER OBJECT OWNER', 'ALTER OBJECT SCHEMA'
    )
    THEN

        -- "old_producteur" n'est pas renseigné
        IF old_producteur IS NULL
        THEN

            RAISE EXCEPTION 'FRE51. Le paramètre "old_producteur" doit être spécifié.'
                USING ERRCODE = 'null_value_not_allowed',
                    DETAIL = format('Opération : %s.', operation) ;

        -- le rôle "old_producteur" n'existe pas
        ELSIF NOT old_producteur IN (
            SELECT pg_roles.rolname
                FROM pg_catalog.pg_roles
        )
        THEN

            RAISE EXCEPTION 'FRE81. Le rôle "%" n''existe pas.', new_producteur
                USING ERRCODE = 'invalid_parameter_value',
                    DETAIL = format('Opération : %s.', operation) ;

        END IF ;
    END IF ;
    
    ------ Super-utilisateur ------
    -- Si le rôle courant est un super-utilisateur, il fera
    -- toujours l'affaire.
    IF current_user IN (
        SELECT pg_roles.rolname 
            FROM pg_catalog.pg_roles 
            WHERE pg_roles.rolsuper
        )
    THEN
        RETURN current_user ;
    END IF ;

    ------ Création d'un rôle ------
    -- > Le rôle doit disposer de l'attribut CREATEROLE.
    IF operation = 'CREATE ROLE'
    THEN

        FOR candidat IN (
            SELECT pg_roles.rolname 
                FROM pg_catalog.pg_roles 
                WHERE pg_roles.rolcreaterole 
                    AND pg_has_role(pg_roles.rolname, 'MEMBER')
                ORDER BY pg_roles.rolname = current_user DESC,
                    pg_roles.rolname
        )
        LOOP

            IF current_setting('server_version_num')::int < 160000
                OR pg_has_role(candidat.rolname, 'SET')
                OR z_asgard.asgard_complete_heritage(candidat.rolname)
            THEN
                RETURN candidat.rolname ;
            END IF ;

        END LOOP ;

        IF current_setting('server_version_num')::int < 160000
        THEN
            RAISE EXCEPTION 'FRE1. Opération interdite. Pour créer un rôle, vous devez être membre d''un rôle disposant de l''attribut CREATEROLE.'
                USING ERRCODE = 'insufficient_privilege' ;
        ELSE
            RAISE EXCEPTION 'FRE1. Opération interdite. Pour créer un rôle, vous devez être membre avec l''option SET d''un rôle disposant de l''attribut CREATEROLE.'
                USING ERRCODE = 'insufficient_privilege' ;
        END IF ;

    ------ Attribution de permissions sur un rôle ------
    -- > Sous les versions de PostgreSQL 15 et inférieures, le rôle
    --   doit disposer de l'attribut CREATEROLE ou doit hériter
    --   d'un rôle qui est un membre direct du rôle visé avec l'option
    --   ADMIN. Sous PostgreSQL 16+, seule la seconde possibilité
    --   est valable.
    ELSIF operation = 'GRANT ROLE'
    THEN

        -- seul un super-utilisateur peut conférer des permissions sur
        -- un super-utilisateur, et il est déjà acquis que ce n'est
        -- pas le cas du rôle courant.
        IF new_producteur IN (
                SELECT pg_roles.rolname 
                    FROM pg_catalog.pg_roles 
                    WHERE pg_roles.rolsuper
            )
        THEN
            RAISE EXCEPTION 'FRE10. Opération interdite. Pour conférer des permissions sur un rôle super-utilisateur, vous devez être super-utilisateur.'
                USING ERRCODE = 'insufficient_privilege',
                    DETAIL = format(
                        'Rôle cible : %I.', new_producteur
                    ) ;
        END IF ;

        -- le rôle courant est-il membre d'un rôle qui
        -- est membre du rôle cible avec l'option ADMIN ?
        FOR candidat IN (
            SELECT
                enfant.rolname
                FROM pg_catalog.pg_roles AS parent
                    INNER JOIN pg_catalog.pg_auth_members
                        ON pg_auth_members.roleid = parent.oid
                    INNER JOIN pg_catalog.pg_roles AS enfant 
                        ON enfant.oid = pg_auth_members.member
                WHERE pg_auth_members.admin_option
                    AND parent.rolname = new_producteur
                    AND pg_has_role(enfant.rolname, 'MEMBER')
                ORDER BY enfant.rolname = current_user DESC,
                    enfant.rolname
        )
        LOOP

            IF pg_has_role(candidat.rolname, 'USAGE')
                OR z_asgard.asgard_complete_heritage(candidat.rolname)
            THEN
                RETURN current_user ;
            ELSIF current_setting('server_version_num')::int < 160000
                OR pg_has_role(candidat.rolname, 'SET')
            THEN
                RETURN candidat.rolname ;
            END IF ;

        END LOOP ;

        -- sous PostgreSQL 15-, le rôle courant est-il membre 
        -- d'un rôle disposant de l'attribut CREATEROLE ?
        IF current_setting('server_version_num')::int < 160000
        THEN

            SELECT pg_roles.rolname 
                INTO executant
                FROM pg_catalog.pg_roles 
                WHERE pg_roles.rolcreaterole 
                    AND pg_has_role(pg_roles.rolname, 'MEMBER')
                ORDER BY pg_roles.rolname = current_user DESC,
                    pg_roles.rolname ;

            IF FOUND 
            THEN
                RETURN executant ;
            END IF ;

            RAISE EXCEPTION 'FRE11. Opération interdite. Pour conférer des permissions sur un rôle, vous devez être membre d''un rôle disposant de l''attribut CREATEROLE ou membre dudit rôle avec l''option ADMIN.'
                USING ERRCODE = 'insufficient_privilege',
                    DETAIL = format(
                        'Rôle cible : %I.', new_producteur
                    ) ;
        ELSE
            RAISE EXCEPTION 'FRE11. Opération interdite. Pour conférer des permissions sur un rôle, vous devez être membre avec l''option SET d''un rôle disposant de l''option ADMIN sur ce rôle.'
                USING ERRCODE = 'insufficient_privilege',
                    DETAIL = format(
                        'Rôle cible : %I.', new_producteur
                    ) ;
        END IF ;

    ------ Création d'un schéma ------
    -- > Le rôle doit disposer du privilège CREATE sur la base,
    --   directement ou par héritage.
    -- > Le rôle doit être membre du propriétaire du schéma (new_producteur).
    --   Sous PostgreSQL 16+, il doit en être membre avec l'option SET.
    ELSIF operation = 'CREATE SCHEMA'
    THEN

        SELECT pg_roles.rolname 
            INTO executant 
            FROM pg_catalog.pg_roles
            WHERE has_database_privilege(pg_roles.rolname, current_database(), 'CREATE') 
                AND (
                    current_setting('server_version_num')::int < 160000 
                        AND pg_has_role(pg_roles.rolname, 'MEMBER')
                    OR current_setting('server_version_num')::int >= 160000 
                        AND pg_has_role(pg_roles.rolname, 'SET')
                )
                AND (
                    current_setting('server_version_num')::int < 160000 
                        AND pg_has_role(pg_roles.rolname, new_producteur, 'MEMBER')
                    OR current_setting('server_version_num')::int >= 160000 
                        AND pg_has_role(pg_roles.rolname, new_producteur, 'SET')
                )
            ORDER BY pg_roles.rolname = current_user DESC,
                pg_roles.rolname ; 

        IF FOUND 
        THEN
            RETURN executant ;
        ELSE
            IF z_asgard.asgard_complete_heritage(new_producteur)
                AND has_database_privilege(current_database(), 'CREATE')
            THEN
                RETURN current_user ;
            ELSIF z_asgard.asgard_heritage_via_g_admin(new_producteur)
                AND has_database_privilege('g_admin', current_database(), 'CREATE')
            THEN
                RETURN 'g_admin' ;
            ELSIF current_setting('server_version_num')::int < 160000
            THEN
                RAISE EXCEPTION 'FRE2. Opération interdite. Pour créer un schéma, vous devez disposer du privilège CREATE sur la base de données et être membre de son futur producteur, ou être membre d''un rôle qui remplit ces deux conditions.'
                    USING ERRCODE = 'insufficient_privilege',
                        DETAIL = format(
                            'Futur producteur : %I.', new_producteur
                        ) ;
            ELSE
                RAISE EXCEPTION 'FRE2. Opération interdite. Pour créer un schéma, vous devez disposer du privilège CREATE sur la base de données et être membre de son futur producteur avec l''option SET, ou être membre avec l''option SET d''un rôle qui remplit ces deux conditions.'
                    USING ERRCODE = 'insufficient_privilege',
                        DETAIL = format(
                            'Futur producteur : %I.', new_producteur
                        ) ;
            END IF ;
        END IF ;

    ------ Modification du nom d'un schéma ------
    -- > Le rôle doit disposer du privilège CREATE sur la base, directement 
    --   ou par héritage.
    -- > Le rôle doit être le propriétaire du schéma (new_producteur) ou 
    --   hériter de ses droits.
    ELSIF operation = 'ALTER SCHEMA RENAME'
    THEN

        SELECT pg_roles.rolname 
            INTO executant 
            FROM pg_catalog.pg_roles
            WHERE has_database_privilege(pg_roles.rolname, current_database(), 'CREATE') 
                AND (
                    current_setting('server_version_num')::int < 160000 
                        AND pg_has_role(pg_roles.rolname, 'MEMBER')
                    OR current_setting('server_version_num')::int >= 160000 
                        AND pg_has_role(pg_roles.rolname, 'SET')
                )
                AND pg_has_role(pg_roles.rolname, new_producteur, 'USAGE')
            ORDER BY pg_roles.rolname = current_user DESC,
                pg_roles.rolname ; 

        IF FOUND 
        THEN
            RETURN executant ;
        ELSE
            IF z_asgard.asgard_complete_heritage(new_producteur)
                AND has_database_privilege(current_database(), 'CREATE')
            THEN
                RETURN current_user ;
            ELSIF z_asgard.asgard_heritage_via_g_admin(new_producteur)
                AND has_database_privilege('g_admin', current_database(), 'CREATE')
            THEN
                RETURN 'g_admin' ;
            ELSE
                RAISE EXCEPTION 'FRE3. Opération interdite. Pour renommer un schéma, vous devez disposer du privilège CREATE sur la base de données et être le producteur du schéma ou hériter de ses droits.'
                    USING ERRCODE = 'insufficient_privilege',
                        DETAIL = format(
                            'Producteur : %I.', new_producteur
                        ) ;
            END IF ;
        END IF ;

    ------ Modification du propriétaire du schéma ------
    -- > Le rôle doit disposer du privilège CREATE sur la base, directement 
    --   ou par héritage.
    -- > Le rôle doit être le propriétaire actuel du schéma (old_producteur) ou 
    --   hériter de ses droits.
    -- > Le rôle doit être membre du nouveau propriétaire du schéma (new_producteur).
    --   Sous PostgreSQL 16+, il doit en être membre avec l'option SET.
    ELSIF operation = 'ALTER SCHEMA OWNER'
    THEN

        SELECT pg_roles.rolname 
            INTO executant 
            FROM pg_catalog.pg_roles
            WHERE has_database_privilege(pg_roles.rolname, current_database(), 'CREATE') 
                AND (
                    current_setting('server_version_num')::int < 160000 
                        AND pg_has_role(pg_roles.rolname, 'MEMBER')
                    OR current_setting('server_version_num')::int >= 160000 
                        AND pg_has_role(pg_roles.rolname, 'SET')
                )
                AND (
                    current_setting('server_version_num')::int < 160000 
                        AND pg_has_role(pg_roles.rolname, new_producteur, 'MEMBER')
                    OR current_setting('server_version_num')::int >= 160000 
                        AND pg_has_role(pg_roles.rolname, new_producteur, 'SET')
                )
                AND pg_has_role(pg_roles.rolname, old_producteur, 'USAGE')
            ORDER BY pg_roles.rolname = current_user DESC,
                pg_roles.rolname ; 

        IF FOUND 
        THEN
            RETURN executant ;
        ELSE
            IF z_asgard.asgard_complete_heritage(new_producteur)
                AND z_asgard.asgard_complete_heritage(old_producteur)
                AND has_database_privilege(current_database(), 'CREATE')
            THEN
                RETURN current_user ;
            ELSIF z_asgard.asgard_heritage_via_g_admin(new_producteur)
                AND z_asgard.asgard_heritage_via_g_admin(old_producteur)
                AND has_database_privilege('g_admin', current_database(), 'CREATE')
            THEN
                RETURN 'g_admin' ;
            ELSIF current_setting('server_version_num')::int < 160000
            THEN
                RAISE EXCEPTION 'FRE4. Opération interdite. Pour changer le producteur d''un schéma, vous devez disposer du privilège CREATE sur la base de données, être membre de son futur producteur et hériter des droits de son ancien producteur, ou être membre d''un rôle qui remplit ces trois conditions.'
                    USING ERRCODE = 'insufficient_privilege',
                        DETAIL = format(
                            'Ancien producteur : %I. Nouveau producteur : %I.',
                            old_producteur, new_producteur
                        ) ;
            ELSE
                RAISE EXCEPTION 'FRE4. Opération interdite. Pour changer le producteur d''un schéma, vous devez disposer du privilège CREATE sur la base de données, être membre de son futur producteur avec l''option SET et hériter des droits de son ancien producteur, ou être membre avec l''option SET d''un rôle qui remplit ces trois conditions.'
                    USING ERRCODE = 'insufficient_privilege',
                        DETAIL = format(
                            'Ancien producteur : %I. Nouveau producteur : %I.',
                            old_producteur, new_producteur
                        ) ;
            END IF ;
        END IF ;

    ------ Suppression d'un schéma -----
    -- > Le rôle doit être le propriétaire du schéma (old_producteur) ou 
    --   hériter de ses droits.
    ELSIF operation = 'DROP SCHEMA'
    THEN

        SELECT pg_roles.rolname 
            INTO executant 
            FROM pg_catalog.pg_roles
            WHERE (
                    current_setting('server_version_num')::int < 160000 
                        AND pg_has_role(pg_roles.rolname, 'MEMBER')
                    OR current_setting('server_version_num')::int >= 160000 
                        AND pg_has_role(pg_roles.rolname, 'SET')
                )
                AND pg_has_role(pg_roles.rolname, old_producteur, 'USAGE')
            ORDER BY pg_roles.rolname = current_user DESC,
                pg_roles.rolname ; 

        IF FOUND 
        THEN
            RETURN executant ;
        ELSE
            IF z_asgard.asgard_complete_heritage(old_producteur)
            THEN
                RETURN current_user ;
            ELSIF z_asgard.asgard_heritage_via_g_admin(old_producteur)
            THEN
                RETURN 'g_admin' ;
            ELSE
                RAISE EXCEPTION 'FRE5. Opération interdite. Pour supprimer un schéma, vous devez disposer du privilège CREATE sur la base de données et être le producteur du schéma ou hériter de ses droits.'
                    USING ERRCODE = 'insufficient_privilege',
                        DETAIL = format(
                            'Ancien producteur : %I.', old_producteur
                        ) ;
            END IF ;
        END IF ;

    ------ Modification du propriétaire des objets ------
    -- > Le rôle doit être le propriétaire actuel des objets
    --   (old_producteur) ou hériter de ses droits.
    -- > Le rôle doit être le nouveau propriétaire des objets
    --   (new_producteur) ou hériter de ses droits.
    -- NB1 : Tous les objets concernés doivent avoir un même ancien 
    -- propriétaire (old_producteur) et un même nouveau propriétaire
    -- (new_producteur), qui doit impérativement être le propriétaire
    -- de leur schéma.
    -- NB2 : Les conditions minimales seraient : 
    -- - pour changer le propriétaire d'un objet, d'hériter 
    --   d'old_producteur, et d'être membre (avec option SET sous 
    --   PostgreSQL 16+) de new_producteur, qui doit disposer du 
    --   privilège CREATE sur le schéma. 
    -- - pour changer le schéma d'un objet, d'hériter d'old_producteur
    --   et d'avoir le privilège CREATE sur le schéma.
    -- Mais, dans le contexte d'un schéma référencé par Asgard, 
    -- on considère que pour avoir CREATE sur le schéma, il faut
    -- hériter de son propriétaire.
    ELSIF operation IN ('ALTER OBJECT OWNER', 'ALTER OBJECT SCHEMA')
    THEN

        SELECT pg_roles.rolname 
            INTO executant
            FROM pg_catalog.pg_roles
            WHERE (
                    current_setting('server_version_num')::int < 160000 
                        AND pg_has_role(pg_roles.rolname, 'MEMBER')
                    OR current_setting('server_version_num')::int >= 160000 
                        AND pg_has_role(pg_roles.rolname, 'SET')
                )
                AND pg_has_role(pg_roles.rolname, old_producteur, 'USAGE')
                AND pg_has_role(pg_roles.rolname, new_producteur, 'USAGE')
            ORDER BY pg_roles.rolname = current_user DESC,
                pg_roles.rolname ; 

        IF FOUND 
        THEN
            RETURN executant ;
        ELSE
            IF z_asgard.asgard_complete_heritage(new_producteur)
                AND z_asgard.asgard_complete_heritage(old_producteur)
            THEN
                RETURN current_user ;
            ELSIF z_asgard.asgard_heritage_via_g_admin(new_producteur)
                AND z_asgard.asgard_heritage_via_g_admin(old_producteur)
            THEN
                RETURN 'g_admin' ;
            ELSIF operation = 'ALTER OBJECT OWNER'
            THEN
                RAISE EXCEPTION 'FRE6. Opération interdite. Pour changer le propriétaire des objets d''un schéma référencé par Asgard, vous devez hériter des droits de l''ancien et du nouveau propriétaire.'
                    USING ERRCODE = 'insufficient_privilege',
                        DETAIL = format(
                            'Ancien propriétaire : %I. Nouveau propriétaire (producteur du schéma) : %I.',
                            old_producteur, new_producteur
                        ) ;
            ELSE
                RAISE EXCEPTION 'FRE7. Opération interdite. Pour changer le schéma d''un objet, vous devez hériter des droits des rôles producteurs de l''ancien et du nouveau schéma.'
                    USING ERRCODE = 'insufficient_privilege',
                        DETAIL = format(
                            'Producteur de l''ancien schéma : %I. Producteur du nouveau schéma : %I.',
                            old_producteur, new_producteur
                        ) ;
            END IF ;
        END IF ;

    ------ Gestion des privilèges sur le schéma et ses objets ------
    ------ Politiques de sécurité niveau ligne ------  
    -- Pour définir les privilèges :
    -- > Le rôle doit être le propriétaire du schéma (new_producteur) ou 
    --   hériter de ses droits.
    -- NB : Le système des "GRANT OPTION" permettrait aussi de transférer des
    -- privilèges, mais il n'est pas pris en compte ici.
    -- Pour les politiques de sécurité niveau ligne : 
    -- > Le rôle doit hériter des droits du propriétaire de l'objet.
    ELSIF operation IN ('PRIVILEGES', 'POLICIES')
    THEN

        SELECT pg_roles.rolname 
            INTO executant 
            FROM pg_catalog.pg_roles
            WHERE (
                    current_setting('server_version_num')::int < 160000 
                        AND pg_has_role(pg_roles.rolname, 'MEMBER')
                    OR current_setting('server_version_num')::int >= 160000 
                        AND pg_has_role(pg_roles.rolname, 'SET')
                )
                AND pg_has_role(pg_roles.rolname, new_producteur, 'USAGE')
            ORDER BY pg_roles.rolname = current_user DESC,
                pg_roles.rolname ; 

        IF FOUND 
        THEN
            RETURN executant ;
        ELSE
            IF z_asgard.asgard_complete_heritage(new_producteur)
            THEN
                RETURN current_user ;
            ELSIF z_asgard.asgard_heritage_via_g_admin(new_producteur)
            THEN
                RETURN 'g_admin' ;
            ELSIF operation = 'PRIVILEGES'
            THEN
                RAISE EXCEPTION 'FRE8. Opération interdite. Pour gérer les privilèges sur un schéma et ses objets, vous devez être le producteur du schéma ou hériter de ses droits.'
                    USING ERRCODE = 'insufficient_privilege',
                        DETAIL = format(
                            'Producteur du schéma : %I.', new_producteur
                        ) ;
            ELSE
                RAISE EXCEPTION 'FRE12. Opération interdite. Pour gérer les politiques de sécurité niveau ligne d''une table, vous devez être le propriétaire de la table ou hériter de ses droits.'
                    USING ERRCODE = 'insufficient_privilege',
                        DETAIL = format(
                            'Propriétaire : %I.', new_producteur
                        ) ;
            END IF ;
        END IF ;

    ------ Privilèges par défaut ------  
    -- > Le rôle doit hériter des droits du rôle pour lequel les privilèges
    --   par défaut sont définis (new_producteur).
    ELSIF operation = 'ALTER DEFAULT PRIVILEGES'
    THEN

        SELECT pg_roles.rolname 
            INTO executant 
            FROM pg_catalog.pg_roles
            WHERE (
                    current_setting('server_version_num')::int < 160000 
                        AND pg_has_role(pg_roles.rolname, 'MEMBER')
                    OR current_setting('server_version_num')::int >= 160000 
                        AND pg_has_role(pg_roles.rolname, 'SET')
                )
                AND pg_has_role(pg_roles.rolname, new_producteur, 'USAGE')
            ORDER BY pg_roles.rolname = current_user DESC,
                pg_roles.rolname ; 

        IF FOUND 
        THEN
            RETURN executant ;
        ELSE
            IF z_asgard.asgard_complete_heritage(new_producteur)
            THEN
                RETURN current_user ;
            -- NB : asgard_heritage_via_g_admin n'est pas utilisée, car il n'y
            -- a pas lieu de présumer que le rôle cible est le producteur
            -- du schéma
            ELSE
                RAISE EXCEPTION 'FRE9. Opération interdite. Pour gérer les privilèges par défaut définis sur un schéma, vous devez être le rôle pour lequel les privilèges par défaut seront appliqués ou hériter de ses droits.'
                    USING ERRCODE = 'insufficient_privilege',
                        DETAIL = format(
                            'Rôle visé : %I.', new_producteur
                        ) ;
            END IF ;
        END IF ;

    ------ Modification d'un enregistrement de la table de gestion ------
    -- > Le rôle doit hériter des privilèges de g_admin ou du producteur
    --   du schéma (new_producteur).
    -- Si new_producteur n'existe pas (no_new_producteur vaut True), le rôle 
    -- devra nécessairement hériter de g_admin.
    ELSIF operation = 'MODIFY GESTION SCHEMA'
    THEN

        SELECT pg_roles.rolname 
            INTO executant 
            FROM pg_catalog.pg_roles
            WHERE (
                    current_setting('server_version_num')::int < 160000 
                        AND pg_has_role(pg_roles.rolname, 'MEMBER')
                    OR current_setting('server_version_num')::int >= 160000 
                        AND pg_has_role(pg_roles.rolname, 'SET')
                )
                AND (
                    NOT no_new_producteur 
                        AND pg_has_role(pg_roles.rolname, new_producteur, 'USAGE')
                    OR pg_has_role(pg_roles.rolname, 'g_admin', 'USAGE')
                )
            ORDER BY pg_roles.rolname = current_user DESC,
                pg_roles.rolname ; 

        IF FOUND 
        THEN
            RETURN executant ;
        ELSE
            IF NOT no_new_producteur 
                AND z_asgard.asgard_complete_heritage(new_producteur)
            THEN
                RETURN current_user ;
            ELSIF z_asgard.asgard_complete_heritage('g_admin')
            THEN
                RETURN current_user ;
            -- on ne tente pas d'utiliser z_asgard.asgard_heritage_via_g_admin(new_producteur),
            -- car cette méthode ne fonctionne que si le rôle est membre de g_admin, auquel cas
            -- la requête précédente aura renvoyé un résultat.
            ELSE
                RAISE EXCEPTION 'FRE13. Opération interdite. Pour modifier un enregistrement de la table de gestion, vous devez hériter des droits du producteur référencé pour le schéma ou de g_admin.'
                    USING ERRCODE = 'insufficient_privilege',
                        DETAIL = format(
                            'Producteur : %I.', new_producteur
                        ) ;
            END IF ;
        END IF ;

    ELSE
        RAISE EXCEPTION 'FRE90. Code d''opération inconnu : "%".', operation
            USING ERRCODE = 'invalid_parameter_value' ;
    END IF ;

EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                            e_hint = PG_EXCEPTION_HINT,
                            e_detl = PG_EXCEPTION_DETAIL,
                            e_errcode = RETURNED_SQLSTATE ;

    RAISE EXCEPTION '%', z_asgard.asgard_prefixe_erreur(e_mssg, 'FRE')
        USING DETAIL = e_detl,
            HINT = e_hint,
            ERRCODE = e_errcode ;
END
$_$ ;

ALTER FUNCTION z_asgard.asgard_cherche_executant(text, text, text)
    OWNER TO g_admin_ext ;

COMMENT ON FUNCTION z_asgard.asgard_cherche_executant(text, text, text) IS 'ASGARD. Recherche le meilleur rôle à faire endosser à l''utilisateur courant pour exécuter une commande d''administration de schéma.' ;


------ 3.21 - CONSULTATION DE LA CONFIGURATION D'ASGARD ------

-- Function: z_asgard.asgard_parametre(z_asgard_admin.asgard_parametre_type)

CREATE OR REPLACE FUNCTION z_asgard.asgard_parametre(parametre z_asgard_admin.asgard_parametre_type) 
    RETURNS boolean
    LANGUAGE plpgsql
    SECURITY DEFINER
    STABLE
    RETURNS NULL ON NULL INPUT
    AS $_$
/* Indique si le paramètre considéré est déclaré dans la table de 
   configuration d''Asgard.

    Cette fonction permet à tout utilisateur d'accéder en lecture
    aux paramètres de configuration d'Asgard, la table de
    configuration z_asgard_admin.asgard_configuration dans laquelle
    ils sont stockés n'étant elle-même accessible qu'aux membres de
    g_admin.

    Parameters
    ----------
    parametre : z_asgard_admin.asgard_parametre_type
        Nom du paramètre. Il peut être saisi sous la forme d'une
        chaîne de caractères sans cast explicite, tant qu'il
        s'agit bien d'un nom de paramètre valide.

    Returns
    -------
    boolean

    Version notes
    -------------
    v1.5.0
        (C) Création.

*/
DECLARE
    e_mssg text ;
    e_hint text ;
    e_detl text ;
    e_errcode text ;
BEGIN

    RETURN asgard_parametre.parametre IN (
        SELECT asgard_configuration.parametre 
            FROM z_asgard_admin.asgard_configuration
        ) ;

EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                            e_hint = PG_EXCEPTION_HINT,
                            e_detl = PG_EXCEPTION_DETAIL,
                            e_errcode = RETURNED_SQLSTATE ;

    RAISE EXCEPTION '%', z_asgard.asgard_prefixe_erreur(e_mssg, 'FPS')
        USING DETAIL = e_detl,
            HINT = e_hint,
            ERRCODE = e_errcode ;

END 
$_$ ;

ALTER FUNCTION z_asgard.asgard_parametre(z_asgard_admin.asgard_parametre_type) OWNER TO g_admin_ext ;

COMMENT ON FUNCTION z_asgard.asgard_parametre(z_asgard_admin.asgard_parametre_type) IS 'ASGARD. Indique si le paramètre considéré est déclaré dans la table de configuration d''Asgard.' ;


------ 3.22 - CREATION D'UN RÔLE ------

-- Function: z_asgard.asgard_create_role(text, boolean, boolean, boolean)

CREATE OR REPLACE FUNCTION z_asgard.asgard_create_role(
    n_role text,
    grant_role_to_createur boolean DEFAULT False,
    with_admin_option boolean DEFAULT False,
    with_set_inherit_option boolean DEFAULT False
)
    RETURNS text
    LANGUAGE plpgsql
    AS $_$
/* Crée un rôle et donne à son créateur les permissions utiles sur ce rôle.

    Cette fonction peut être utilisé par tout rôle membre d'un rôle
    disposant de l'attribut CREATEROLE, là où une commande
    "CREATE ROLE" usuelle requiert que le rôle courant ait 
    lui-même CREATEROLE.

    Sous PostgreSQL 16+, le rôle créateur est quoi qu'il arrive 
    automatiquement rendu membre du nouveau rôle avec ADMIN OPTION, 
    mais sans SET et INHERIT. Si le paramètre optionnel 
    "with_set_inherit" vaut True, la fonction lui confèrera également 
    SET et INHERIT.
    
    Sous les versions antérieures, si le paramètre optionnel 
    "grant_role_to_createur" vaut True, la fonction rend également le rôle 
    créateur membre du nouveau rôle (si ce n'est pas un super-utilisateur).
    Il recevra l'option ADMIN si et seulement si le paramètre optionnel
    "with_admin_option" vaut True.

    Parameters
    ----------
    n_role : text
        Nom du rôle à créer.
    grant_role_to_createur : boolean, default False
        Si True, le rôle créateur sera rendu membre du rôle qu'il 
        vient de créer. Ce paramètre n'est pas pris en compte sous
        PostgreSQL 16+, où PostgreSQL confère automatiquement cette
        permission.
    with_admin_option : boolean, default False
        Si True, sous réserve que "grant_role_to_createur" vaille
        également True, le rôle créateur sera rendu membre du rôle qu'il
        vient de créer avec l'option ADMIN. Si False, il n'aura pas 
        l'option ADMIN. Ce paramètre n'est pas pris en compte sous
        PostgreSQL 16+, où confère automatiquement l'option ADMIN.
    with_set_inherit_option : boolean, default False
        Si True, sous réserve que "grant_role_to_createur" vaille
        également True, le rôle créateur recevra les options SET
        et INHERIT sur le rôle qu'il vient de créer. Ce paramètre
        n'est pris en compte que sous PostgreSQL 16+.

    Returns
    -------
    text
        Le nom du rôle qui a créé le rôle cible.

    Raises
    ------
    duplicate_object
        FRC1. S'il existe déjà un rôle de même nom.

    Version notes
    -------------
    v1.5.0
        (C) Création.

*/
DECLARE
    executant text ;
    utilisateur text := current_user ;
    executant_is_superuser boolean ;
    e_mssg text ;
    e_detl text ;
    e_hint text ;
    e_errcode text ;
    e_schema text ;
BEGIN
 
    IF n_role IN (SELECT pg_roles.rolname FROM pg_catalog.pg_roles)
    THEN
        RAISE EXCEPTION 'FRC1. Le rôle % existe déjà.', n_role ;
    END IF ;

    -- choix d'un rôle habilité à exécuter les commandes (sinon
    -- asgard_cherche_executant émet une erreur)
    executant := z_asgard.asgard_cherche_executant('CREATE ROLE') ;
    EXECUTE format('SET ROLE %I', executant) ;

    EXECUTE format('CREATE ROLE %I', n_role) ;
    RAISE NOTICE '... Le rôle de groupe % a été créé.', n_role ;

    SELECT pg_roles.rolsuper 
        INTO executant_is_superuser
        FROM pg_catalog.pg_roles 
        WHERE pg_roles.rolname = executant ;

    -- sous PG16+, le rôle créateur aura été automatiquement rendu membre
    -- du nouveau rôle avec ADMIN OPTION
    -- on lui donne également les options SET et INHERIT si demandé
    -- par l'argument with_set_inherit_option
    IF current_setting('server_version_num')::int >= 160000
        AND with_set_inherit_option
        AND NOT executant_is_superuser
    THEN
        EXECUTE format('GRANT %I TO %I WITH SET True, INHERIT True', n_role, executant) ;
        RAISE NOTICE '%', format(
                '... Octroi au rôle %I, créateur de %I, de l''accès aux privilèges de ce rôle.', 
                executant, 
                n_role
            ) ;
    END IF ;

    -- dans les versions antérieures, on lui donne cette permission si ce n'est
    -- pas un super-utilisateur et sauf paramétrage contraire. Ceci permet 
    -- notamment aux administrateurs délégués disposant de CREATEROLE mais non 
    -- membres de g_admin de conserver la maîtrise des rôles qu'ils ont créés.
    IF current_setting('server_version_num')::int < 160000
        AND grant_role_to_createur
        AND NOT executant_is_superuser
    THEN
        IF with_admin_option
        THEN
            EXECUTE format('GRANT %I TO %I WITH ADMIN OPTION', n_role, executant) ;
            RAISE NOTICE '%', format(
                '... Permission accordée à %s sur le rôle %s avec l''option ADMIN.', 
                executant, 
                n_role
            ) ;
        ELSE
            EXECUTE format('GRANT %I TO %I', n_role, executant) ;
            RAISE NOTICE '%', format(
                '... Permission accordée à %s sur le rôle %s.', 
                executant, 
                n_role
            ) ;
        END IF ;
    END IF ;

    EXECUTE format('SET ROLE %I', utilisateur) ;

    RETURN executant ;

EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                            e_hint = PG_EXCEPTION_HINT,
                            e_detl = PG_EXCEPTION_DETAIL,
                            e_errcode = RETURNED_SQLSTATE,
                            e_schema = SCHEMA_NAME ;
    
    RAISE EXCEPTION '%', z_asgard.asgard_prefixe_erreur(e_mssg, 'FCR')
        USING DETAIL = e_detl,
            HINT = e_hint,
            SCHEMA = e_schema,
            ERRCODE = e_errcode ;

END
$_$ ;

ALTER FUNCTION z_asgard.asgard_create_role(text, boolean, boolean, boolean)
    OWNER TO g_admin_ext ;

COMMENT ON FUNCTION z_asgard.asgard_create_role(text, boolean, boolean, boolean) IS 'ASGARD. Crée un rôle et donne à son créateur les permissions utiles sur ce rôle.' ;


------ 3.23 - RECUPERATION D'INFORMATIONS DE LA TABLE DE GESTION ------

-- Function: z_asgard.asgard_producteur_apparent(text, boolean, boolean)

CREATE OR REPLACE FUNCTION z_asgard.asgard_producteur_apparent(
    nom_schema text,
    quoted boolean DEFAULT False,
    compare_oid boolean DEFAULT False
) 
    RETURNS text
    LANGUAGE plpgsql
    SECURITY DEFINER
    RETURNS NULL ON NULL INPUT
    AS $_$
/* Renvoie le producteur référencé dans la table de gestion d'Asgard 
   pour le schéma considéré.

    Cette fonction est utilisable par tous les utilisateurs.
    Elle sert notamment à déterminer le rôle dont l'utilisateur courant
    doit hériter des privilèges pour voir l'enregistrement correspondant
    à un schéma référencé dans les vues z_asgard.gestion_schema_usr et
    z_asgard.gestion_schema_etr.

    Si le schéma n'est pas référencé, elle renvoie toujours NULL.

    Si le schéma est référencé, elle renvoie toujours un nom de rôle 
    valide, y compris pour les schémas inactifs dont le producteur déclaré 
    n'existe pas nécessairement :
    - Si le champ "oid_producteur" est renseigné et qu'il existe bien un rôle
      portant cet identifiant, la fonction renvoie le nom de ce rôle.
    - À défaut, s'il existe un rôle portant le nom renseigné dans le champ 
      "producteur", ce nom est renvoyé.
    - Sinon, elle renvoie 'g_admin'.

    Parameters
    ----------
    nom_schema : text
        Nom du schéma. La fonction tolère les identifiants PostgreSQL 
        (cf. "quoted" ci-dessous).
    quoted : boolean, default False
        Si True, la fonction considèrera que le nom fourni par la fonction
        n'est pas un nom brut mais qu'il est présenté sous la forme
        d'un identifiant PostgreSQL valide.
    compare_oid : boolean, default False
        Si True, la fonction compare le nom fourni en argument avec
        l'identifiant renseigné dans le champ "oid_schema" au lieu du
        nom. Cette option est pertinente quand est il certain que 
        l'identifiant est renseigné, tandis que le nom peut
        avoir été modifié. Si le schéma est inactif et le paramètre 
        "compare_oid" vaut True, la fonction renvoie toujours NULL.

    Returns
    -------
    text or NULL
        Le nom du producteur du schéma si ce dernier est référencé dans
        la table de gestion d'Asgard, sinon NULL. Cf. description pour
        plus de détails.

    Version notes
    -------------
    v1.5.0
        (C) Création.

*/
DECLARE
    e_mssg text ;
    e_hint text ;
    e_detl text ;
    e_schema text ;
    e_errcode text ;
    prod_name text ;
BEGIN

    SELECT 
        coalesce(pg_roles_oid.rolname, pg_roles_name.rolname, 'g_admin')
        INTO prod_name
        FROM z_asgard_admin.gestion_schema
            LEFT JOIN pg_catalog.pg_roles AS pg_roles_oid
                ON pg_roles_oid.oid = gestion_schema.oid_producteur
            LEFT JOIN pg_catalog.pg_roles AS pg_roles_name
                ON pg_roles_name.rolname = gestion_schema.producteur
        WHERE quoted AND NOT coalesce(compare_oid, False)
                AND quote_ident(gestion_schema.nom_schema) = asgard_producteur_apparent.nom_schema
            OR NOT coalesce(quoted, False) AND NOT coalesce(compare_oid, False)
                AND gestion_schema.nom_schema = asgard_producteur_apparent.nom_schema
            OR quoted AND compare_oid 
                AND gestion_schema.oid_schema IS NOT NULL
                AND gestion_schema.oid_schema::regnamespace::text = asgard_producteur_apparent.nom_schema
            OR NOT coalesce(quoted, False) AND compare_oid 
                AND gestion_schema.oid_schema IS NOT NULL
                AND gestion_schema.oid_schema::regnamespace::text = quote_ident(asgard_producteur_apparent.nom_schema) ;

    RETURN prod_name ;

EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                            e_hint = PG_EXCEPTION_HINT,
                            e_detl = PG_EXCEPTION_DETAIL,
                            e_errcode = RETURNED_SQLSTATE,
                            e_schema = SCHEMA_NAME ;

    RAISE EXCEPTION '%', z_asgard.asgard_prefixe_erreur(e_mssg, 'FPA')
        USING DETAIL = e_detl,
            HINT = e_hint,
            SCHEMA = coalesce(nullif(e_schema, ''), nullif(nom_schema, ''), '???'),
            ERRCODE = e_errcode ;

END 
$_$ ;

ALTER FUNCTION z_asgard.asgard_producteur_apparent(text, boolean, boolean) OWNER TO g_admin_ext ;

COMMENT ON FUNCTION z_asgard.asgard_producteur_apparent(text, boolean, boolean) IS 'ASGARD. Renvoie le producteur référencé dans la table de gestion d''Asgard pour le schéma considéré.' ;


-- Function: z_asgard.asgard_est_reference(text, boolean)

CREATE OR REPLACE FUNCTION z_asgard.asgard_est_reference(
    nom_schema text,
    quoted boolean DEFAULT False
) 
    RETURNS boolean
    LANGUAGE plpgsql
    SECURITY DEFINER
    AS $_$
/* Indique si le schéma est référencé dans la table de gestion d'Asgard.

    Cette fonction est utilisable par tous les utilisateurs.

    Concrètement, elle regarde s'il existe dans la table de gestion
    un enregistrement tel que le nom renseigné dans le champ "nom_schema"
    correspond au nom donné en argument.

    Parameters
    ----------
    nom_schema : text
        Nom du schéma. La fonction tolère les identifiants PostgreSQL 
        (cf. "quoted" ci-dessous).
    quoted : boolean, default False
        Si True, la fonction considèrera que le nom fourni par la fonction
        n'est pas un nom brut mais qu'il est présenté sous la forme
        d'un identifiant PostgreSQL valide.

    Returns
    -------
    boolean
        True si un schéma du nom considéré est référencé dans la table de
        gestion. False sinon.

    Version notes
    -------------
    v1.5.0
        (C) Création.

*/
DECLARE
    e_mssg text ;
    e_hint text ;
    e_detl text ;
    e_schema text ;
    e_errcode text ;

BEGIN

    IF nom_schema IS NULL
    THEN 
        RETURN False ;
    END IF ;

    IF quoted 
    THEN
        RETURN nom_schema IN (
            SELECT quote_ident(gestion_schema.nom_schema)
                FROM z_asgard_admin.gestion_schema
        ) ;
    ELSE
        RETURN nom_schema IN (
            SELECT gestion_schema.nom_schema
                FROM z_asgard_admin.gestion_schema
        ) ;
    END IF ;

EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                            e_hint = PG_EXCEPTION_HINT,
                            e_detl = PG_EXCEPTION_DETAIL,
                            e_errcode = RETURNED_SQLSTATE,
                            e_schema = SCHEMA_NAME ;

    RAISE EXCEPTION '%', z_asgard.asgard_prefixe_erreur(e_mssg, 'FRN')
        USING DETAIL = e_detl,
            HINT = e_hint,
            SCHEMA = coalesce(nullif(e_schema, ''), nullif(nom_schema, ''), '???'),
            ERRCODE = e_errcode ;

END 
$_$ ;

ALTER FUNCTION z_asgard.asgard_est_reference(text, boolean) OWNER TO g_admin_ext ;

COMMENT ON FUNCTION z_asgard.asgard_est_reference(text, boolean) IS 'ASGARD. Indique si le schéma est référencé dans la table de gestion d''Asgard.' ;


-- Function: z_asgard.asgard_est_reference(oid)

CREATE OR REPLACE FUNCTION z_asgard.asgard_est_reference(
    oid_schema oid
) 
    RETURNS boolean
    LANGUAGE plpgsql
    SECURITY DEFINER
    AS $_$
/* Indique si l'OID de schéma considéré est référencé dans la table de 
   gestion d'Asgard.

    Cette fonction est utilisable par tous les utilisateurs.

    Concrètement, elle regarde s'il existe dans la table de gestion
    un enregistrement tel que l'OID renseignée dans le champ "oid_schema"
    correspond à l'identifiant donné en argument.

    Les OID n'étant renseignés dans la table de gestion que pour les
    schémas actifs, la fonction renverra False si le schéma,
    soit n'est pas référencé dans la table de gestion, soit n'est pas
    actif.

    Parameters
    ----------
    oid_schema : oid
        OID du schéma.

    Returns
    -------
    boolean
        True si l'OID de schéma considéré est référencé dans la table de
        gestion. False sinon.

    Version notes
    -------------
    v1.5.0
        (C) Création.

*/
DECLARE
    e_mssg text ;
    e_hint text ;
    e_detl text ;
    e_schema text ;
    e_errcode text ;

BEGIN

    IF oid_schema IS NULL
    THEN 
        RETURN False ;
    END IF ;

    RETURN oid_schema IN (
        SELECT gestion_schema.oid_schema
            FROM z_asgard_admin.gestion_schema
            WHERE gestion_schema.oid_schema IS NOT NULL
    ) ;

EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                            e_hint = PG_EXCEPTION_HINT,
                            e_detl = PG_EXCEPTION_DETAIL,
                            e_errcode = RETURNED_SQLSTATE,
                            e_schema = SCHEMA_NAME ;

    RAISE EXCEPTION '%', z_asgard.asgard_prefixe_erreur(e_mssg, 'FRO')
        USING DETAIL = e_detl,
            HINT = e_hint,
            SCHEMA = e_schema,
            ERRCODE = e_errcode ;

END 
$_$ ;

ALTER FUNCTION z_asgard.asgard_est_reference(oid) OWNER TO g_admin_ext ;

COMMENT ON FUNCTION z_asgard.asgard_est_reference(oid) IS 'ASGARD. Indique si l''OID de schéma considéré est référencé dans la table de gestion d''Asgard.' ;


-- Function: z_asgard.asgard_est_actif(text, boolean)

CREATE OR REPLACE FUNCTION z_asgard.asgard_est_actif(
    nom_schema text,
    quoted boolean DEFAULT False
) 
    RETURNS boolean
    LANGUAGE plpgsql
    SECURITY DEFINER
    RETURNS NULL ON NULL INPUT
    AS $_$
/* Indique si le schéma est référencé en tant que schéma actif 
   dans la table de gestion d'Asgard.

    Un schéma est dit "actif" lorsqu'il existe effectivement dans
    la base. Le champ "creation" de la table de gestion vaut alors
    True. Sinon, il est dit "inactif" et "creation" vaut False.

    Cette fonction est utilisable par tous les utilisateurs.

    Elle renvoie toujours NULL lorsque le schéma n'est pas
    référencé.

    Parameters
    ----------
    nom_schema : text
        Nom du schéma. La fonction tolère les identifiants PostgreSQL 
        (cf. "quoted" ci-dessous).
    quoted : boolean, default False
        Si True, la fonction considèrera que le nom fourni par la fonction
        n'est pas un nom brut mais qu'il est présenté sous la forme
        d'un identifiant PostgreSQL valide.

    Returns
    -------
    boolean or NULL
        NULL si le schéma n'est pas référencé.
        True si le schéma est référencé et marqué comme actif.
        False si le schéma est référencé et marqué comme inactif.

    Version notes
    -------------
    v1.5.0
        (C) Création.

*/
DECLARE
    e_mssg text ;
    e_hint text ;
    e_detl text ;
    e_schema text ;
    e_errcode text ;
    actif boolean ;
BEGIN

    IF quoted 
    THEN
        SELECT creation INTO actif
            FROM z_asgard_admin.gestion_schema
            WHERE quote_ident(gestion_schema.nom_schema) = asgard_est_actif.nom_schema ;
    ELSE
        SELECT creation INTO actif
            FROM z_asgard_admin.gestion_schema
            WHERE gestion_schema.nom_schema = asgard_est_actif.nom_schema ;
    END IF ;

    RETURN actif ;

EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                            e_hint = PG_EXCEPTION_HINT,
                            e_detl = PG_EXCEPTION_DETAIL,
                            e_errcode = RETURNED_SQLSTATE,
                            e_schema = SCHEMA_NAME ;

    RAISE EXCEPTION '%', z_asgard.asgard_prefixe_erreur(e_mssg, 'FEA')
        USING DETAIL = e_detl,
            HINT = e_hint,
            SCHEMA = coalesce(nullif(e_schema, ''), nullif(nom_schema, ''), '???'),
            ERRCODE = e_errcode ;

END 
$_$ ;

ALTER FUNCTION z_asgard.asgard_est_actif(text, boolean) OWNER TO g_admin_ext ;

COMMENT ON FUNCTION z_asgard.asgard_est_actif(text, boolean) IS 'ASGARD. Indique si le schéma est référencé en tant que schéma actif dans la table de gestion d''Asgard.' ;


-- Function: z_asgard.asgard_information(text, boolean, boolean)

CREATE OR REPLACE FUNCTION z_asgard.asgard_information(
    nom_schema text,
    quoted boolean DEFAULT False,
    consolide_roles boolean DEFAULT False
) 
    RETURNS TABLE (
        bloc varchar(1),
        nomenclature boolean,
        niv1 varchar,
        niv1_abr varchar,
        niv2 varchar,
        niv2_abr varchar,
        oid_schema oid,
        creation boolean,
        producteur varchar,
        oid_producteur oid,
        editeur varchar,
        oid_editeur oid,
        lecteur varchar, 
        oid_lecteur oid
    )
    LANGUAGE plpgsql
    SECURITY DEFINER
    AS $_$
/* Renvoie les informations enregistrées dans la table de gestion
   pour le schéma considéré.

    Cette fonction est utilisable par tous les utilisateurs.

    Parameters
    ----------
    nom_schema : text
        Nom du schéma. La fonction tolère les identifiants PostgreSQL 
        (cf. "quoted" ci-dessous).
    quoted : boolean, default False
        Si True, la fonction considèrera que le nom fourni par la fonction
        n'est pas un nom brut mais qu'il est présenté sous la forme
        d'un identifiant PostgreSQL valide.
    consolide_roles : boolean, default False
        Si True, la fonction ne renvoie pas les noms de rôles
        renseignés dans les champs "producteur", "editeur" et "lecteur"
        de la table de gestion, mais les déduit des identifiants 
        contenus dans les champs "oid_producteur", "oid_editeur" et
        "oid_lecteur". Ceci assure que les noms soient les bons, au
        cas où ils auraient été renommés depuis la dernière modification
        de l'enregistrement de la table de gestion. Si les rôles ont
        été supprimés entre temps, les noms et OID renvoyés seront NULL.
        Si ce paramètre est ignoré pour un schéma inactif, dont les
        champs "oid_producteur", "oid_editeur" et "oid_lecteur" ne sont
        jamais renseignés et les champs "producteur", "editeur" et "lecteur"
        ne sont pas présumés contenir les noms de rôles existants.

    Returns
    -------
    table
        Une table dont les champs correspondent à ceux de la table
        z_asgard_admin.gestion_schema, hors "ctrl" et "nom_schema".
        Si le schéma n'est pas référencé, la table sera vide.

    Raises
    ------
    raise_exception
        FIF1. Si "consolide_roles" vaut True et que le producteur 
        référencé pour un schéma actif n'existe pas ou plus.

    Version notes
    -------------
    v1.5.0
        (C) Création.

*/
DECLARE
    e_mssg text ;
    e_hint text ;
    e_detl text ;
    e_schema text ;
    e_errcode text ;
    info record ;
    cons_producteur varchar ;
    cons_editeur varchar ;
    cons_lecteur varchar ;
BEGIN

    SELECT
        gestion_schema.*
        INTO info
        FROM z_asgard_admin.gestion_schema
        WHERE quote_ident(gestion_schema.nom_schema) = asgard_information.nom_schema 
                AND quoted
            OR gestion_schema.nom_schema = asgard_information.nom_schema
                AND NOT coalesce(quoted, False) ;

    IF NOT FOUND 
        OR NOT coalesce(consolide_roles, False)
        OR NOT info.creation
    THEN
        RETURN QUERY (
            SELECT 
                info.bloc,
                info.nomenclature,
                info.niv1,
                info.niv1_abr,
                info.niv2,
                info.niv2_abr,
                info.oid_schema,
                info.creation,
                info.producteur,
                info.oid_producteur,
                info.editeur,
                info.oid_editeur,
                info.lecteur, 
                info.oid_lecteur
        ) ;
    ELSE

        SELECT pg_roles.rolname
            INTO cons_producteur 
            FROM pg_catalog.pg_roles
            WHERE pg_roles.oid = info.oid_producteur ;
        
        IF NOT FOUND
        THEN
            RAISE EXCEPTION 'FIF1. Anomalie critique. Le rôle référencé comme producteur du schéma % n''existe pas.', nom_schema
                USING ERRCODE = 'raise_exception',
                    DETAIL = format(
                        'Nom du producteur : %I. OID du producteur : %I.',
                        info.producteur, info.oid_producteur
                    ),
                    SCHEMA = nom_schema ;
        END IF ;

        IF info.editeur = 'public'
        THEN
            cons_editeur := 'public' ;
        ELSE
            SELECT pg_roles.rolname
                INTO cons_editeur 
                FROM pg_catalog.pg_roles
                WHERE pg_roles.oid = info.oid_editeur ;
        END IF ;

        IF info.lecteur = 'public'
        THEN
            cons_lecteur := 'public' ;
        ELSE
            SELECT pg_roles.rolname
                INTO cons_lecteur 
                FROM pg_catalog.pg_roles
                WHERE pg_roles.oid = info.oid_lecteur ;
        END IF ;

        RETURN QUERY (
            SELECT
                info.bloc,
                info.nomenclature,
                info.niv1,
                info.niv1_abr,
                info.niv2,
                info.niv2_abr,
                info.oid_schema,
                info.creation,
                cons_producteur AS producteur,
                CASE WHEN cons_producteur IS NOT NULL
                THEN
                    info.oid_producteur
                END AS oid_producteur,
                cons_editeur AS editeur,
                CASE WHEN cons_editeur IS NOT NULL
                THEN
                    info.oid_editeur
                END AS oid_editeur,
                cons_lecteur AS lecteur,
                CASE WHEN cons_lecteur IS NOT NULL
                THEN
                    info.oid_lecteur
                END AS oid_lecteur
        ) ;

    END IF ;

EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                            e_hint = PG_EXCEPTION_HINT,
                            e_detl = PG_EXCEPTION_DETAIL,
                            e_errcode = RETURNED_SQLSTATE,
                            e_schema = SCHEMA_NAME ;

    RAISE EXCEPTION '%', z_asgard.asgard_prefixe_erreur(e_mssg, 'FIF')
        USING DETAIL = e_detl,
            HINT = e_hint,
            SCHEMA = coalesce(nullif(e_schema, ''), nullif(nom_schema, ''), '???'),
            ERRCODE = e_errcode ;

END 
$_$ ;

ALTER FUNCTION z_asgard.asgard_information(text, boolean, boolean) OWNER TO g_admin_ext ;

COMMENT ON FUNCTION z_asgard.asgard_information(text, boolean, boolean) IS 'ASGARD. Renvoie les informations enregistrées dans la table de gestion pour le schéma considéré.' ;


-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


--------------------------------------------
------ 4 - CREATION DES EVENT TRIGGERS ------
--------------------------------------------
/* 4.1 - EVENT TRIGGER SUR ALTER SCHEMA
   4.2 - EVENT TRIGGER SUR CREATE SCHEMA
   4.3 - EVENT TRIGGER SUR DROP SCHEMA
   4.4 - EVENT TRIGGER SUR CREATE OBJET
   4.5 - EVENT TRIGGER SUR ALTER OBJET */


------ 4.1 - EVENT TRIGGER SUR ALTER SCHEMA ------

-- Function: z_asgard_admin.asgard_on_alter_schema()

CREATE OR REPLACE FUNCTION z_asgard_admin.asgard_on_alter_schema()
    RETURNS event_trigger
    LANGUAGE plpgsql
    AS $_$
/* Fonction exécutée par le déclencheur sur évènement asgard_on_alter_schema,
   qui répercute sur la table de gestion d'Asgard les changements de noms et
   propriétaires réalisés par des commandes ALTER SCHEMA directes.

    Elle n'écrit pas directement dans la table z_asgard_admin.gestion_schema,
    mais dans la vue modifiable z_asgard.gestion_schema_etr.

    Cette fonction veille aussi à ce que les propriétaires des schémas
    d'Asgard ne soient jamais modifiés accidentellement.

    Raises
    ------
    insufficient_privilege
        EAS1 et EAS2. Lorsque l'utilisateur ne dispose pas du privilège
        USAGE donnant accès au schéma z_asgard et du privilège UPDATE
        permettant de modifier la vue z_asgard.gestion_schema_etr
        respectivement. Ces erreurs ne devraient jamais se produire, 
        ces privilèges étant conférés au pseudo-rôle "public" lors de 
        l'activation d'Asgard.
    raise_exception
        EAS3 et EAS4. Si l'utilisateur tente de changer le propriétaire des
        schémas z_asgard et z_asgard_admin respectivement.

    Version notes
    -------------
    v1.5.0
        (M) Ajout de contrôles assurant que les propriétaires
            des schémas d'Asgard ne soient jamais modifiés.
        (M) Recours à asgard_cherche_executant et 
            asgard_producteur_apparent pour déterminer si le schéma
            est déjà référencé dans la table de gestion d'Asgard et, 
            le cas échéant, trouver un rôle habilité à intervenir 
            sur l'enregistrement.
        (m) Amélioration de la gestion des messages d'erreur.
        (m) Petite simplification du code.
        (d) Enrichissement du descriptif.

*/
DECLARE
    obj record ;
    e_mssg text ;
    e_hint text ;
    e_detl text ;
    e_schema text ;
    e_errcode text ;
    utilisateur text := current_user ;
    executant text ;
    producteur text ;
BEGIN
    ------ CONTROLES DES PRIVILEGES ------
    IF NOT has_schema_privilege('z_asgard', 'USAGE')
    THEN
        RAISE EXCEPTION 'EAS1. Schéma z_asgard inaccessible.'
            USING ERRCODE = 'insufficient_privilege' ;
    END IF ;
    
    IF NOT has_table_privilege('z_asgard.gestion_schema_etr', 'UPDATE')
    THEN
        RAISE EXCEPTION 'EAS2. Permissions insuffisantes pour la vue z_asgard.gestion_schema_etr.' 
            USING ERRCODE = 'insufficient_privilege' ;
    END IF ;

    -- seules les commandes (a priori une seule) portant
    -- sur les objets de type schéma sont prises en compte
	FOR obj IN (
        SELECT 
            pg_namespace.oid, 
            pg_namespace.nspname,
            pg_namespace.nspowner, 
            pg_roles.rolname 
        FROM pg_event_trigger_ddl_commands()
            INNER JOIN pg_catalog.pg_namespace
                ON objid = pg_namespace.oid
            INNER JOIN pg_catalog.pg_roles
                ON pg_namespace.nspowner = pg_roles.oid
        WHERE object_type = 'schema'
    )
    LOOP

        ------ PROTECTION DES SCHEMAS D'ASGARD -------
        IF obj.nspname = 'z_asgard'
            AND NOT obj.rolname = 'g_admin_ext'
        THEN
            RAISE EXCEPTION 'EAS3. Opération interdite. Le propriétaire du schéma z_asgard doit rester g_admin_ext.'
                USING SCHEMA = 'z_asgard',
                    ERRCODE = 'raise_exception' ;
        END IF ;

        IF obj.nspname = 'z_asgard_admin'
            AND NOT obj.rolname = 'g_admin'
        THEN
            RAISE EXCEPTION 'EAS4. Opération interdite. Le propriétaire du schéma z_asgard_admin doit rester g_admin.'
                USING SCHEMA = 'z_asgard_admin',
                    ERRCODE = 'raise_exception' ;
        END IF ;

        producteur := z_asgard.asgard_producteur_apparent(
            obj.nspname, compare_oid := True
        ) ;
        -- non nul si et seulement si le schéma est référencé dans la
        -- table de gestion
        -- on utilise l'OID renseigné dans la table de gestion et pas le nom
        -- au cas où le schéma aurait changé de nom

        IF producteur IS NOT NULL
        THEN
            -- choix d'un rôle habilité à exécuter les commandes (sinon
            -- asgard_cherche_executant émet une erreur)
            executant := z_asgard.asgard_cherche_executant(
                'MODIFY GESTION SCHEMA', 
                new_producteur := producteur
            ) ;
            EXECUTE format('SET ROLE %I', executant) ;
        
            ------ RENAME ------
            UPDATE z_asgard.gestion_schema_etr
                SET nom_schema = obj.nspname,
                    ctrl = ARRAY['RENAME', 'x7-A;#rzo']
                WHERE oid_schema = obj.oid
                    AND NOT nom_schema = obj.nspname ;
            IF FOUND
            THEN
                RAISE NOTICE '... Le nom du schéma % a été mis à jour dans la table de gestion.',  obj.nspname ;
            END IF ;

            ------ OWNER TO ------
            UPDATE z_asgard.gestion_schema_etr
                SET producteur = obj.rolname,
                    oid_producteur = obj.nspowner,
                    ctrl = ARRAY['OWNER', 'x7-A;#rzo']
                WHERE oid_schema = obj.oid
                    AND NOT oid_producteur = obj.nspowner ;
            IF FOUND
            THEN
                RAISE NOTICE '... Le producteur du schéma % a été mis à jour dans la table de gestion.',  obj.nspname ;
            END IF ;

            EXECUTE format('SET ROLE %I', utilisateur) ;
        END IF ;

    END LOOP ;

EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                            e_hint = PG_EXCEPTION_HINT,
                            e_detl = PG_EXCEPTION_DETAIL,
                            e_errcode = RETURNED_SQLSTATE,
                            e_schema = SCHEMA_NAME ;
    
    RAISE EXCEPTION '%', z_asgard.asgard_prefixe_erreur(e_mssg, 'EAS')
        USING DETAIL = e_detl,
            HINT = e_hint,
            SCHEMA = e_schema,
            ERRCODE = e_errcode ;

END
$_$ ;

ALTER FUNCTION z_asgard_admin.asgard_on_alter_schema()
    OWNER TO g_admin ;
    
COMMENT ON FUNCTION z_asgard_admin.asgard_on_alter_schema() IS 'ASGARD. Fonction exécutée par le déclencheur sur évènement asgard_on_alter_schema, qui répercute sur la table de gestion d''Asgard les changements de noms et propriétaires réalisés par des commandes ALTER SCHEMA directes.' ;


-- Event Trigger: asgard_on_alter_schema

CREATE EVENT TRIGGER asgard_on_alter_schema ON DDL_COMMAND_END
    WHEN TAG IN ('ALTER SCHEMA')
    EXECUTE PROCEDURE z_asgard_admin.asgard_on_alter_schema() ;

COMMENT ON EVENT TRIGGER asgard_on_alter_schema IS 'ASGARD. Déclencheur sur évènement qui répercute sur la table de gestion d''Asgard les changements de noms et propriétaires réalisés par des commandes ALTER SCHEMA directes.' ;



------ 4.2 - EVENT TRIGGER SUR CREATE SCHEMA ------

-- Function: z_asgard_admin.asgard_on_create_schema()

CREATE OR REPLACE FUNCTION z_asgard_admin.asgard_on_create_schema() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $_$
/* Fonction exécutée par le déclencheur sur évènement asgard_on_create_schema,
   qui répercute sur la table de gestion d'Asgard les créations de schémas réalisées
   par des commandes CREATE SCHEMA directes.

    Elle n'écrit pas directement dans la table z_asgard_admin.gestion_schema,
    mais dans la vue modifiable z_asgard.gestion_schema_etr.

    Raises
    ------
    insufficient_privilege
        ECS1 et ECS2. Lorsque l'utilisateur ne dispose pas du privilège
        USAGE donnant accès au schéma z_asgard (ECS1) et des privilèges,
        INSERT et UPDATE permettant de modifier la vue 
        z_asgard.gestion_schema_etr (ECS2). Ces erreurs ne devraient jamais 
        se produire, ces privilèges étant conférés au pseudo-rôle "public" lors 
        de l'activation d'Asgard.

    Version notes
    -------------
    v1.5.0
        (M) Recours à asgard_cherche_executant et 
            asgard_producteur_apparent pour déterminer si le schéma
            est déjà référencé dans la table de gestion d'Asgard et, 
            le cas échéant, trouver un rôle habilité à intervenir 
            sur l'enregistrement.
        (m) Amélioration de la gestion des messages d'erreur.
        (d) Enrichissement du descriptif.

*/
DECLARE
    obj record ;
    e_mssg text ;
    e_hint text ;
    e_detl text ;
    e_schema text ;
    e_errcode text ;
    utilisateur text := current_user ;
    executant text ;
    producteur text ;
BEGIN
    ------ CONTROLES DES PRIVILEGES ------
    IF NOT has_schema_privilege('z_asgard', 'USAGE')
    THEN
        RAISE EXCEPTION 'ECS1. Schéma z_asgard inaccessible.'
            USING ERRCODE = 'insufficient_privilege' ;
    END IF ;
    
    IF NOT has_table_privilege('z_asgard.gestion_schema_etr', 'UPDATE')
        OR NOT has_table_privilege('z_asgard.gestion_schema_etr', 'INSERT')
    THEN
        RAISE EXCEPTION 'ECS2. Permissions insuffisantes pour la vue z_asgard.gestion_schema_etr.'
            USING ERRCODE = 'insufficient_privilege' ;
    END IF ;

    -- seules les commandes (a priori une seule) portant
    -- sur les objets de type schéma sont prises en compte
	FOR obj IN (
        SELECT 
            pg_namespace.oid, 
            pg_namespace.nspname,
            pg_namespace.nspowner, 
            pg_roles.rolname 
        FROM pg_event_trigger_ddl_commands()
            INNER JOIN pg_catalog.pg_namespace
                ON objid = pg_namespace.oid
            INNER JOIN pg_catalog.pg_roles
                ON pg_namespace.nspowner = pg_roles.oid
        WHERE object_type = 'schema'
    )
    LOOP

        producteur := z_asgard.asgard_producteur_apparent(obj.nspname) ;
        -- non nul si et seulement si le schéma est déjà référencé dans la
        -- table de gestion

        IF producteur IS NOT NULL
        THEN
            -- choix d'un rôle habilité à exécuter les commandes (sinon
            -- asgard_cherche_executant émet une erreur)
            executant := z_asgard.asgard_cherche_executant(
                'MODIFY GESTION SCHEMA', 
                new_producteur := producteur
            ) ;
            EXECUTE format('SET ROLE %I', executant) ;
    
            ------ SCHEMA PRE-ENREGISTRE DANS GESTION_SCHEMA ------
            UPDATE z_asgard.gestion_schema_etr
                SET oid_schema = obj.oid,
                    producteur = obj.rolname,
                    oid_producteur = obj.nspowner,
                    creation = True,
                    ctrl = ARRAY['CREATE', 'x7-A;#rzo']
                WHERE nom_schema = obj.nspname
                    AND NOT creation ;
                -- creation vaut true si et seulement si la création a été initiée via la table
                -- de gestion et, dans ce cas, il n'est pas nécessaire de réintervenir dessus
            IF FOUND
            THEN
                RAISE NOTICE '... Le schéma % apparaît désormais comme "créé" dans la table de gestion.', obj.nspname ;
            END IF ;

            EXECUTE format('SET ROLE %I', utilisateur) ;            

        ------ SCHEMA NON REPERTORIE DANS GESTION_SCHEMA ------
        ELSE
            INSERT INTO z_asgard.gestion_schema_etr (
                oid_schema, nom_schema, producteur, oid_producteur, 
                creation, ctrl
            ) VALUES (
                obj.oid, obj.nspname, obj.rolname, obj.nspowner, 
                True, ARRAY['CREATE', 'x7-A;#rzo']
            ) ;
            RAISE NOTICE '... Le schéma % a été enregistré dans la table de gestion.', obj.nspname ;
        END IF ;
        
	END LOOP ;
    
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                            e_hint = PG_EXCEPTION_HINT,
                            e_detl = PG_EXCEPTION_DETAIL,
                            e_errcode = RETURNED_SQLSTATE,
                            e_schema = SCHEMA_NAME ;
    
    RAISE EXCEPTION '%', z_asgard.asgard_prefixe_erreur(e_mssg, 'ECS')
        USING DETAIL = e_detl,
            HINT = e_hint,
            SCHEMA = e_schema,
            ERRCODE = e_errcode ;
               
END
$_$ ;

ALTER FUNCTION z_asgard_admin.asgard_on_create_schema()
    OWNER TO g_admin ;
    
COMMENT ON FUNCTION z_asgard_admin.asgard_on_create_schema() IS 'ASGARD. Fonction exécutée par le déclencheur sur évènement asgard_on_create_schema, qui répercute sur la table de gestion d''Asgard les créations de schémas réalisées par des commandes CREATE SCHEMA directes.' ;


-- Event Trigger: asgard_on_create_schema

CREATE EVENT TRIGGER asgard_on_create_schema ON DDL_COMMAND_END
    WHEN TAG IN ('CREATE SCHEMA')
    EXECUTE PROCEDURE z_asgard_admin.asgard_on_create_schema() ;
    
COMMENT ON EVENT TRIGGER asgard_on_create_schema IS 'ASGARD. Déclencheur sur évènement qui répercute sur la table de gestion d''Asgard les créations de schémas réalisées par des commandes CREATE SCHEMA directes.' ;
    

------ 4.3 - EVENT TRIGGER SUR DROP SCHEMA ------

-- Function: z_asgard_admin.asgard_on_drop_schema()

CREATE OR REPLACE FUNCTION z_asgard_admin.asgard_on_drop_schema() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $_$
/* Fonction exécutée par le déclencheur sur évènement asgard_on_drop_schema,
   qui répercute sur la table de gestion d'Asgard les suppressions de schémas
   réalisées par des commandes DROP SCHEMA directes ou dans le cadre de la
   suppression d'une extension.

    Elle n'écrit pas directement dans la table z_asgard_admin.gestion_schema,
    mais dans la vue modifiable z_asgard.gestion_schema_etr.

    Raises
    ------
    insufficient_privilege
        EDS1 et EDS2. Lorsque l'utilisateur ne dispose pas du privilège
        USAGE donnant accès au schéma z_asgard (EDS1) et des privilèges
        SELECT et UPDATE permettant de consulter et modifier la vue 
        z_asgard.gestion_schema_etr (EDS2). Ces erreurs ne devraient jamais 
        se produire, ces privilèges étant conférés au pseudo-rôle "public" lors 
        de l'activation d'Asgard.

    Version notes
    -------------
    v1.5.0
        (M) Recours à asgard_cherche_executant et 
            asgard_producteur_apparent pour déterminer si le schéma
            est déjà référencé dans la table de gestion d'Asgard et, 
            le cas échéant, trouver un rôle habilité à intervenir 
            sur l'enregistrement.
        (m) Amélioration de la gestion des messages d'erreur.
        (d) Enrichissement du descriptif.

*/
DECLARE
	obj record ;
    objname text ;
    e_mssg text ;
    e_hint text ;
    e_detl text ;
    e_schema text ;
    e_errcode text ;
    utilisateur text := current_user ;
    executant text ;
    producteur text ;
BEGIN
    ------ CONTROLES DES PRIVILEGES ------
    IF NOT has_schema_privilege('z_asgard', 'USAGE')
    THEN
        RAISE EXCEPTION 'EDS1. Schéma z_asgard inaccessible.'
            USING ERRCODE = 'insufficient_privilege' ;
    END IF ;
    
    IF NOT has_table_privilege('z_asgard.gestion_schema_etr', 'UPDATE')
        OR NOT has_table_privilege('z_asgard.gestion_schema_etr', 'SELECT')
    THEN
        RAISE EXCEPTION 'EDS2. Permissions insuffisantes pour la vue z_asgard.gestion_schema_etr.'
            USING ERRCODE = 'insufficient_privilege' ;
    END IF ;
    
	FOR obj IN SELECT * FROM pg_event_trigger_dropped_objects()
                    WHERE object_type = 'schema'
    LOOP

        producteur := z_asgard.asgard_producteur_apparent(
            obj.object_identity, quoted := True
        ) ;
        -- non nul si et seulement si le schéma est référencé dans la
        -- table de gestion

        IF producteur IS NOT NULL
        THEN
            -- choix d'un rôle habilité à exécuter les commandes (sinon
            -- asgard_cherche_executant émet une erreur)
            executant := z_asgard.asgard_cherche_executant(
                'MODIFY GESTION SCHEMA', 
                new_producteur := producteur
            ) ;
            EXECUTE format('SET ROLE %I', executant) ;

            ------ ENREGISTREMENT DE LA SUPPRESSION ------
            -- avec réinitialisation du bloc, pour les schémas
            -- qui avait été mis à la corbeille
            UPDATE z_asgard.gestion_schema_etr
                SET creation = false,
                    oid_schema = NULL,
                    ctrl = ARRAY['DROP', 'x7-A;#rzo'],
                    bloc = substring(nom_schema, '^([a-z])_')
                WHERE quote_ident(nom_schema) = obj.object_identity
                RETURNING nom_schema INTO objname ;    
            IF FOUND THEN
                RAISE NOTICE '... La suppression du schéma % a été enregistrée dans la table de gestion (creation = False).', objname ;
            END IF ;

            EXECUTE format('SET ROLE %I', utilisateur) ;

        END IF ;
            
	END LOOP ;
    
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                            e_hint = PG_EXCEPTION_HINT,
                            e_detl = PG_EXCEPTION_DETAIL,
                            e_errcode = RETURNED_SQLSTATE,
                            e_schema = SCHEMA_NAME ;
    
    RAISE EXCEPTION '%', z_asgard.asgard_prefixe_erreur(e_mssg, 'EDS')
        USING DETAIL = e_detl,
            HINT = e_hint,
            SCHEMA = e_schema,
            ERRCODE = e_errcode ;
               
END
$_$ ;

ALTER FUNCTION z_asgard_admin.asgard_on_drop_schema()
    OWNER TO g_admin;

COMMENT ON FUNCTION z_asgard_admin.asgard_on_drop_schema() IS 'ASGARD. Fonction exécutée par le déclencheur sur évènement asgard_on_drop_schema, qui répercute sur la table de gestion d''Asgard les suppressions de schémas réalisées par des commandes DROP SCHEMA directes ou dans le cadre de la suppression d''une extension.' ;


-- Event Trigger: asgard_on_drop_schema

CREATE EVENT TRIGGER asgard_on_drop_schema ON SQL_DROP
    WHEN TAG IN ('DROP SCHEMA', 'DROP EXTENSION', 'DROP OWNED')
    EXECUTE PROCEDURE z_asgard_admin.asgard_on_drop_schema() ;
    
COMMENT ON EVENT TRIGGER asgard_on_drop_schema IS 'ASGARD. Déclencheur sur évènement qui répercute sur la table de gestion d''Asgard les suppressions de schémas réalisées par des commandes DROP SCHEMA directes ou dans le cadre de la suppression d''une extension.' ;



------ 4.4 - EVENT TRIGGER SUR CREATE OBJET ------

-- Function: z_asgard_admin.asgard_on_create_objet()

CREATE OR REPLACE FUNCTION z_asgard_admin.asgard_on_create_objet()
    RETURNS event_trigger
    LANGUAGE plpgsql
    AS $_$
/* Fonction exécutée par le déclencheur sur évènement asgard_on_create_objet,
   qui applique aux nouveaux objets créés les droits pré-définis pour le schéma
   dans la table de gestion d'Asgard.

    Elle est activée par toutes les commandes CREATE portant sur des objets qui
    dépendent d'un schéma et ont un propriétaire.

    Elle ignore les objets dont le schéma n'est pas référencé par Asgard.

    Raises
    ------
    insufficient_privilege
        ECO1. Lorsque l'utilisateur ne dispose pas du privilège
        USAGE donnant accès au schéma z_asgard. Cette erreur ne 
        devrait jamais se produire, ce privilège étant conféré 
        au pseudo-rôle "public" lors de l'activation d'Asgard.

    Version notes
    -------------
    v1.5.0
        (M) Recours à asgard_cherche_executant pour trouver des 
            rôles habilités, le cas échéant, à modifier les 
            propriétaires des objets et/ou leurs privilèges.
        (m) Recours à asgard_information pour déterminer si le schéma
            de l'objet est référencé et récupérer ses rôles producteur,
            éditeur et lecteur.
        (m) Amélioration de la gestion des messages d'erreur.
        (d) Enrichissement du descriptif.

*/
DECLARE
    obj record ;
    src record ;
    proprietaire text ;
    xowner text ;
    e_mssg text ;
    e_hint text ;
    e_detl text ;
    e_schema text ;
    e_errcode text ;
    l text ;
    executant text ;
    utilisateur text := current_user ;
    m_hint text := '' ;
    m_detail text := '' ;
BEGIN
    ------ CONTROLES DES PRIVILEGES ------
    IF NOT has_schema_privilege('z_asgard', 'USAGE')
    THEN
        RAISE EXCEPTION 'ECO1. Schéma z_asgard inaccessible.'
            USING ERRCODE = 'insufficient_privilege' ;
    END IF ;
    
    -- on examine toutes les commandes portant 
    -- sur un objet rattaché à un schéma référencé par Asgard
    -- et marqué comme actif
    FOR obj IN (
        SELECT DISTINCT
            com.classid, com.objid, com.object_type, 
            com.schema_name, com.object_identity,
            info.producteur, info.editeur, info.lecteur
            FROM pg_event_trigger_ddl_commands() AS com
                NATURAL LEFT JOIN z_asgard.asgard_information(
                    com.schema_name,
                    consolide_roles := True
                ) AS info
            WHERE com.schema_name IS NOT NULL AND info.creation
            ORDER BY com.object_type DESC
    )
    LOOP
            
        -- récupération du nom du champ contenant le propriétaire
        -- courant de l'objet
        SELECT attname::text INTO xowner
            FROM pg_catalog.pg_attribute
            WHERE attrelid = obj.classid AND attname ~ 'owner' ;
            -- pourrait ne rien renvoyer pour certains pseudo-objets
            -- comme les "table constraint"
            
        IF FOUND
        THEN               
            -- récupération du propriétaire courant de l'objet
            -- génère une erreur si la requête ne renvoie rien
            EXECUTE format(
                'SELECT pg_roles.rolname 
                    FROM pg_catalog.%2$s
                        INNER JOIN pg_catalog.pg_roles
                            ON %1$s = pg_roles.oid
                    WHERE %2$s.oid = %3$s',
                xowner, obj.classid::regclass, obj.objid
            )
                INTO STRICT proprietaire ;
                    
            -- si le propriétaire courant n'est pas le producteur
            IF NOT obj.producteur = proprietaire
            THEN

                -- choix d'un rôle habilité à exécuter les commandes (sinon
                -- asgard_cherche_executant émet une erreur)
                executant := z_asgard.asgard_cherche_executant(
                    'ALTER OBJECT OWNER', 
                    new_producteur := obj.producteur,
                    old_producteur := proprietaire
                ) ;
                EXECUTE format('SET ROLE %I', executant) ;
            
                ------ PROPRIETAIRE DE L'OBJET (DROITS DU PRODUCTEUR) ------
                RAISE NOTICE 'réattribution de la propriété de % au rôle producteur du schéma :',
                    obj.object_identity ;
                l := format(
                    'ALTER %s %s OWNER TO %I',
                    CASE WHEN obj.object_type = 'statistics object'
                        THEN 'statistics' ELSE obj.object_type END,
                    obj.object_identity, 
                    obj.producteur
                ) ;
                EXECUTE l ;
                RAISE NOTICE '> %', l ;
                
                ------ PROPRIETAIRE DE LA FAMILLE D'OPERATEURS IMPLICITE ------
                -- Lorsque le paramètre FAMILY n'est pas spécifié à la
                -- création d'une classe d'opérateurs, une famille de
                -- même nom que la classe d'opérateurs est créée... en
                -- passant entre les mailles du filets du déclencheur.
                IF obj.object_type = 'operator class' AND EXISTS (
                    SELECT * FROM pg_catalog.pg_opclass
                        LEFT JOIN pg_catalog.pg_opfamily
                            ON pg_opfamily.oid = opcfamily
                        WHERE obj.objid = pg_opclass.oid
                            AND opfname = opcname
                            AND opfmethod = opcmethod
                            AND opfnamespace = opcnamespace
                            AND NOT opfowner = quote_ident(obj.producteur)::regrole
                    )
                THEN
                    l := format(
                        'ALTER operator family %s OWNER TO %I',
                        obj.object_identity, 
                        obj.producteur
                    ) ;
                    EXECUTE l ;
                    RAISE NOTICE '> %', l ;
                END IF ;
                
                EXECUTE format('SET ROLE %I', utilisateur) ;

            END IF ;
            
            ------ DROITS DE L'EDITEUR ------
            IF obj.editeur IS NOT NULL
            THEN

                -- choix d'un rôle habilité à exécuter les commandes (sinon
                -- asgard_cherche_executant émet une erreur)
                executant := z_asgard.asgard_cherche_executant(
                    'PRIVILEGES', 
                    new_producteur := obj.producteur
                ) ;
                EXECUTE format('SET ROLE %I', executant) ;

                -- sur les tables :
                IF obj.object_type IN ('table', 'view', 'materialized view', 'foreign table')
                THEN
                    RAISE NOTICE 'application des privilèges standards pour le rôle éditeur du schéma :' ;
                    l := format('GRANT SELECT, UPDATE, DELETE, INSERT ON TABLE %s TO %I',
                        obj.object_identity, obj.editeur) ;
                    EXECUTE l ;
                    RAISE NOTICE '> %', l ;
                    
                -- sur les séquences :
                ELSIF obj.object_type IN ('sequence')
                THEN
                    RAISE NOTICE 'application des privilèges standards pour le rôle éditeur du schéma :' ;
                    l := format('GRANT SELECT, USAGE ON SEQUENCE %s TO %I',
                        obj.object_identity, obj.editeur) ;
                    EXECUTE l ;
                    RAISE NOTICE '> %', l ;
                END IF ;

                EXECUTE format('SET ROLE %I', utilisateur) ;

            END IF ;
            
            ------ DROITS DU LECTEUR ------
            IF obj.lecteur IS NOT NULL
            THEN

                -- choix d'un rôle habilité à exécuter les commandes (sinon
                -- asgard_cherche_executant émet une erreur)
                executant := z_asgard.asgard_cherche_executant(
                    'PRIVILEGES', 
                    new_producteur := obj.producteur
                ) ;
                EXECUTE format('SET ROLE %I', executant) ;

                -- sur les tables :
                IF obj.object_type IN ('table', 'view', 'materialized view', 'foreign table')
                THEN
                    RAISE NOTICE 'application des privilèges standards pour le rôle lecteur du schéma :' ;
                    l := format('GRANT SELECT ON TABLE %s TO %I',
                        obj.object_identity, obj.lecteur) ;
                    EXECUTE l ;
                    RAISE NOTICE '> %', l ;
                    
                -- sur les séquences :
                ELSIF obj.object_type IN ('sequence')
                THEN
                    RAISE NOTICE 'application des privilèges standards pour le rôle lecteur du schéma :' ;
                    l := format('GRANT SELECT ON SEQUENCE %s TO %I',
                        obj.object_identity, obj.lecteur) ;
                    EXECUTE l ;
                    RAISE NOTICE '> %', l ;    
                END IF ;

                EXECUTE format('SET ROLE %I', utilisateur) ;

            END IF ;
            
            ------ VERIFICATION DES DROITS SUR LES SOURCES DES VUES -------
            -- génère un avertissement lorsque le rôle propriétaire de la vue
            -- n'a pas les droits nécessaires pour consulter ses données sources
            IF obj.object_type IN ('view', 'materialized view')
            THEN
                FOR src IN (
                    SELECT
                        DISTINCT
                        pg_namespace.nspname,
                        pg_class.relnamespace,
                        pg_class.relname,
                        t.liblg,
                        pg_class.relowner,
                        info.oid_producteur, info.oid_editeur, info.oid_lecteur,
                        info.producteur, info.editeur, info.lecteur
                        FROM pg_catalog.pg_rewrite
                            LEFT JOIN pg_catalog.pg_depend
                                ON pg_depend.objid = pg_rewrite.oid
                            LEFT JOIN pg_catalog.pg_class
                                ON pg_class.oid = pg_depend.refobjid
                            NATURAL LEFT JOIN z_asgard.asgard_information(
                                pg_class.relnamespace::regnamespace::text,
                                quoted := True,
                                consolide_roles := True
                            ) AS info
                            LEFT JOIN pg_catalog.pg_namespace
                                ON pg_class.relnamespace = pg_namespace.oid
                            LEFT JOIN unnest(
                                ARRAY[
                                    'Table', 'Table partitionnée', 'Vue', 'Vue matérialisée', 
                                    'Table étrangère', 'Séquence'
                                ],
                                ARRAY['r', 'p', 'v', 'm', 'f', 'S']
                            ) AS t (liblg, libcrt)
                                ON pg_class.relkind = t.libcrt
                        WHERE pg_rewrite.ev_class = obj.objid
                            AND pg_rewrite.rulename = '_RETURN'
                            AND pg_rewrite.ev_type = '1'
                            AND pg_rewrite.ev_enabled = 'O'
                            AND pg_rewrite.is_instead
                            AND pg_depend.classid = 'pg_rewrite'::regclass
                            AND pg_depend.refclassid = 'pg_class'::regclass
                            AND pg_depend.deptype = 'n'
                            AND NOT pg_depend.refobjid = obj.objid
                            AND (
                                NOT has_schema_privilege(
                                    obj.producteur, pg_class.relnamespace, 'USAGE'
                                )
                                OR NOT has_table_privilege(
                                    obj.producteur, pg_class.oid, 'SELECT'
                                )
                            )
                    )
                LOOP
                    -- cas d'un schéma référencé
                    IF src.producteur IS NOT NULL
                    THEN

                        IF src.oid_lecteur IS NULL
                        THEN
                            m_hint := format(
                                'Pour faire du producteur de la vue%s le lecteur du schéma source, vous pouvez lancer la commande suivante : UPDATE z_asgard.gestion_schema_usr SET lecteur = %L WHERE nom_schema = %L.',
                                CASE WHEN obj.object_type = 'materialized view' 
                                    THEN ' matérialisée' ELSE '' END,
                                obj.producteur, src.nspname
                            ) ;
                        ELSE
                            m_hint := format(
                                'Pour faire du producteur de la vue%s le lecteur du schéma source, vous pouvez lancer la commande suivante : GRANT %I TO %I.',
                                CASE WHEN obj.object_type = 'materialized view' 
                                    THEN ' matérialisée' ELSE '' END,
                                src.lecteur, obj.producteur
                            ) ;
                        END IF ;

                        m_detail := format(
                            '%s source %I.%I, producteur %I, éditeur %I, lecteur %I.',
                            src.liblg, src.nspname, src.relname, src.producteur,
                            coalesce(src.editeur, 'non défini'),
                            coalesce(src.lecteur, 'non défini')
                        ) ;
                    
                    -- cas d'un schéma non référencé
                    ELSE

                        m_detail := format(
                            '%s source %I.%I, propriétaire %s.', 
                            src.liblg, src.nspname, src.relname, 
                            src.relowner::regrole
                        ) ;
                    
                    END IF ;

                    RAISE WARNING 'Le producteur du schéma de la vue% ne dispose pas des droits nécessaires pour accéder à ses données sources.',
                        format(
                            '%s %s', 
                            CASE WHEN obj.object_type = 'materialized view'
                                THEN 'matérialisée ' ELSE '' END, 
                            obj.object_identity
                        )
                        USING DETAIL = m_detail,
                            HINT = m_hint ;
                    
                END LOOP ;
            END IF ;  
        END IF ;
    END LOOP ;

EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                            e_hint = PG_EXCEPTION_HINT,
                            e_detl = PG_EXCEPTION_DETAIL,
                            e_errcode = RETURNED_SQLSTATE,
                            e_schema = SCHEMA_NAME ;
    
    RAISE EXCEPTION '%', z_asgard.asgard_prefixe_erreur(e_mssg, 'ECO')
        USING DETAIL = e_detl,
            HINT = e_hint,
            SCHEMA = e_schema,
            ERRCODE = e_errcode ;
               
END
$_$ ;

ALTER FUNCTION z_asgard_admin.asgard_on_create_objet()
    OWNER TO g_admin ;

COMMENT ON FUNCTION z_asgard_admin.asgard_on_create_objet() IS 'ASGARD. Fonction exécutée par le déclencheur sur évènement asgard_on_create_objet, qui applique aux nouveaux objets créés les droits pré-définis pour le schéma dans la table de gestion d''Asgard.' ;


-- Event Trigger: asgard_on_create_objet

DO
$$
BEGIN
    IF current_setting('server_version_num')::int < 100000
    THEN 
        CREATE EVENT TRIGGER asgard_on_create_objet ON DDL_COMMAND_END
            WHEN TAG IN ('CREATE TABLE', 'CREATE TABLE AS', 'CREATE VIEW',
                'CREATE MATERIALIZED VIEW', 'SELECT INTO', 'CREATE SEQUENCE', 'CREATE FOREIGN TABLE',
                'CREATE FUNCTION', 'CREATE OPERATOR', 'CREATE AGGREGATE', 'CREATE COLLATION',
                'CREATE CONVERSION', 'CREATE DOMAIN', 'CREATE TEXT SEARCH CONFIGURATION',
                'CREATE TEXT SEARCH DICTIONARY', 'CREATE TYPE', 'CREATE OPERATOR CLASS',
                'CREATE OPERATOR FAMILY')
            EXECUTE PROCEDURE z_asgard_admin.asgard_on_create_objet() ;
    ELSIF current_setting('server_version_num')::int < 110000
    THEN 
        -- + CREATE STATISTICS pour PG 10
        CREATE EVENT TRIGGER asgard_on_create_objet ON DDL_COMMAND_END
            WHEN TAG IN ('CREATE TABLE', 'CREATE TABLE AS', 'CREATE VIEW',
                'CREATE MATERIALIZED VIEW', 'SELECT INTO', 'CREATE SEQUENCE', 'CREATE FOREIGN TABLE',
                'CREATE FUNCTION', 'CREATE OPERATOR', 'CREATE AGGREGATE', 'CREATE COLLATION',
                'CREATE CONVERSION', 'CREATE DOMAIN', 'CREATE TEXT SEARCH CONFIGURATION',
                'CREATE TEXT SEARCH DICTIONARY', 'CREATE TYPE', 'CREATE OPERATOR CLASS',
                'CREATE OPERATOR FAMILY', 'CREATE STATISTICS')
            EXECUTE PROCEDURE z_asgard_admin.asgard_on_create_objet() ;
    ELSE
        -- + CREATE PROCEDURE pour PG 11+
        CREATE EVENT TRIGGER asgard_on_create_objet ON DDL_COMMAND_END
            WHEN TAG IN ('CREATE TABLE', 'CREATE TABLE AS', 'CREATE VIEW',
                'CREATE MATERIALIZED VIEW', 'SELECT INTO', 'CREATE SEQUENCE', 'CREATE FOREIGN TABLE',
                'CREATE FUNCTION', 'CREATE OPERATOR', 'CREATE AGGREGATE', 'CREATE COLLATION',
                'CREATE CONVERSION', 'CREATE DOMAIN', 'CREATE TEXT SEARCH CONFIGURATION',
                'CREATE TEXT SEARCH DICTIONARY', 'CREATE TYPE', 'CREATE OPERATOR CLASS',
                'CREATE OPERATOR FAMILY', 'CREATE STATISTICS', 'CREATE PROCEDURE')
            EXECUTE PROCEDURE z_asgard_admin.asgard_on_create_objet() ;
    END IF ;
END
$$ ;

COMMENT ON EVENT TRIGGER asgard_on_create_objet IS 'ASGARD. Déclencheur sur évènement qui applique aux nouveaux objets créés les droits pré-définis pour le schéma dans la table de gestion d''Asgard.' ;



------ 4.5 - EVENT TRIGGER SUR ALTER OBJET ------

-- Function: z_asgard_admin.asgard_on_alter_objet()

CREATE OR REPLACE FUNCTION z_asgard_admin.asgard_on_alter_objet() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $_$
/* Fonction exécutée par le déclencheur sur évènement asgard_on_alter_objet,
   qui assure que le producteur d'un schéma reste propriétaire de tous les
   objets qui en dépendent.

    Elle est activée par toutes les commandes ALTER portant sur des objets qui
    dépendent d'un schéma et ont un propriétaire, mais n'aura réellement d'effet
    que pour celles qui affectent la cohérence des propriétaires :

    * Les ALTER ... SET SCHEMA lorsque le schéma cible a un producteur différent
      de celui du schéma d'origine. Elle modifie alors le propriétaire de l'objet
      selon le producteur du nouveau schéma.
    * Les ALTER ... OWNER TO, dont elle inhibe l'effet en rendant la propriété de
      l'objet au producteur du schéma.

    Elle n'agit pas sur les privilèges. Elle ignore les objets dont le schéma
    (après exécution de la commande) n'est pas référencé par Asgard, sauf pour
    les objets des schémas d'Asgard, dont elle assure que les propriétaires
    ne soient pas indûment modifiés.

    Raises
    ------
    insufficient_privilege
        EAO1. Lorsque l'utilisateur ne dispose pas du privilège
        USAGE donnant accès au schéma z_asgard. Cette erreur ne devrait
        jamais se produire, ce privilège étant conféré au pseudo-rôle 
        "public" lors de l'activation d'Asgard.
        EAO6. Lorsque le rôle courant n'hérite pas des privilèges du 
        rôle qu'il a désigné comme propriétaire de l'objet (il doit
        au moins en être membre, sans quoi la commande aurait échoué).
        Cette condition est nécessaire pour que la fonction puisse
        lancer la commande qui désignera le bon propriétaire pour l'objet.
    raise_exception
        EAO3 à EAO5. Si l'utilisateur tente de changer le propriétaire d'un
        objet des schémas z_asgard et z_asgard_admin.

    Version notes
    -------------
    v1.5.0
        (M) Ajout de contrôles assurant que les propriétaires des
            objets des schémas d'Asgard ne soient jamais modifiés.
        (M) Recours à asgard_cherche_executant pour trouver des 
            rôles habilités, le cas échéant, à modifier les 
            propriétaires des objets.
        (m) Recours à asgard_information pour déterminer si le schéma
            de l'objet est référencé et récupérer son producteur.
        (m) Amélioration de la gestion des messages d'erreur.
        (d) Enrichissement du descriptif.

*/
DECLARE
    obj record ;
    a_producteur text ;
    commande text ;
    executant text ;
    utilisateur text := current_user ;
    e_mssg text ;
    e_hint text ;
    e_detl text ;
    e_schema text ;
    e_errcode text ;
    xowner text ;
BEGIN
    ------ CONTROLES DES PRIVILEGES ------
    IF NOT has_schema_privilege('z_asgard', 'USAGE')
    THEN
        RAISE EXCEPTION 'EAO1. Schéma z_asgard inaccessible.'
            USING ERRCODE = 'insufficient_privilege' ;
    END IF ;

    -- on examine toutes les commandes portant 
    -- sur un objet rattaché à un schéma
    -- + récupération du producteur du schéma, s'il
    -- est référencé par Asgard.
    FOR obj IN (
        SELECT DISTINCT
            com.classid, com.objid, com.object_type,
            com.schema_name, com.object_identity,
            info.oid_producteur,
            info.producteur AS n_producteur
            FROM pg_event_trigger_ddl_commands() AS com
                NATURAL LEFT JOIN z_asgard.asgard_information(
                    com.schema_name,
                    consolide_roles := True
                ) AS info
            WHERE com.schema_name IS NOT NULL
            ORDER BY com.object_type DESC
    )
    LOOP
            
        -- récupération du nom du champ contenant le propriétaire
        -- de l'objet
        SELECT attname::text INTO xowner
            FROM pg_catalog.pg_attribute
            WHERE attrelid = obj.classid AND attname ~ 'owner' ;
            -- ne renvoie rien pour certains pseudo-objets comme les
            -- "table constraint"
            
        IF FOUND
        THEN             
            -- récupération du propriétaire courant de l'objet
            -- génère une erreur si la requête ne renvoie rien
            EXECUTE format(
                'SELECT pg_roles.rolname 
                    FROM pg_catalog.%2$s
                        INNER JOIN pg_catalog.pg_roles
                            ON %1$s = pg_roles.oid
                    WHERE %2$s.oid = %3$s',
                xowner, obj.classid::regclass, obj.objid
            )
                INTO STRICT a_producteur ;

            ------ OBJET D'ASGARD -------
            IF obj.schema_name = 'z_asgard'
            THEN

                -- tous les objets de z_asgard doivent appartenir à 
                -- g_admin_ext
                IF NOT a_producteur = 'g_admin_ext'
                THEN 
                    RAISE EXCEPTION 'EAO3. Opération interdite. Le propriétaire des objets du schéma z_asgard doit rester g_admin_ext.'
                        USING SCHEMA = 'z_asgard',
                        ERRCODE = 'raise_exception' ;
                END IF ;

            END IF ;

            IF obj.schema_name = 'z_asgard_admin'
            THEN

                -- tous les objets de z_asgard_admin doivent appartenir à 
                -- g_admin, sauf la fonction z_asgard_admin.asgard_visibilite_admin_after(),
                -- qui doit appartenir à un super-utilisateur.
                IF obj.classid::regclass::text = 'pg_proc'
                    AND obj.objid::regprocedure::text = 'z_asgard_admin.asgard_visibilite_admin_after()'
                THEN

                    IF NOT (
                        SELECT pg_roles.rolsuper 
                            FROM pg_roles 
                            WHERE pg_roles.rolname = a_producteur
                        )
                    THEN
                        RAISE EXCEPTION 'EAO4. Opération interdite. Le propriétaire de la fonction z_asgard_admin.asgard_visibilite_admin_after() doit toujours être un super-utilisateur.'
                            USING SCHEMA = 'z_asgard_admin',
                            ERRCODE = 'raise_exception' ;
                    END IF ;

                ELSIF NOT a_producteur = 'g_admin'
                THEN 
                    RAISE EXCEPTION 'EAO5. Opération interdite. Le propriétaire des objets du schéma z_asgard_admin doit rester g_admin_ext.'
                        USING SCHEMA = 'z_asgard_admin',
                        ERRCODE = 'raise_exception' ;
                END IF ;

            END IF ;
            
            ------ OBJET D'UN SCHEMA REFERENCE ------
            -- si les deux rôles sont différents
            IF obj.n_producteur IS NOT NULL
                AND NOT obj.n_producteur = a_producteur
            THEN 

                -- choix d'un rôle habilité à exécuter les commandes (sinon
                -- asgard_cherche_executant émet une erreur)
                executant := z_asgard.asgard_cherche_executant(
                    'ALTER OBJECT OWNER', 
                    new_producteur := obj.n_producteur, 
                    old_producteur := a_producteur
                ) ;
                EXECUTE format('SET ROLE %I', executant) ;

                -- l'objet est attribué au propriétaire désigné pour le schéma
                -- (n_producteur)
                RAISE NOTICE 'attribution de la propriété de % au rôle producteur du schéma :',
                    obj.object_identity ;
                commande := format(
                    'ALTER %s %s OWNER TO %I',
                    CASE WHEN obj.object_type = 'statistics object'
                        THEN 'statistics' ELSE obj.object_type END,
                    obj.object_identity, 
                    obj.n_producteur
                ) ;
                EXECUTE commande ;
                RAISE NOTICE '> %', commande ;

                EXECUTE format('SET ROLE %I', utilisateur) ;
              
            END IF ;

        END IF ;

    END LOOP ;

EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                            e_hint = PG_EXCEPTION_HINT,
                            e_detl = PG_EXCEPTION_DETAIL,
                            e_errcode = RETURNED_SQLSTATE,
                            e_schema = SCHEMA_NAME ;
    
    RAISE EXCEPTION '%', z_asgard.asgard_prefixe_erreur(e_mssg, 'EAO')
        USING DETAIL = e_detl,
            HINT = e_hint,
            SCHEMA = e_schema,
            ERRCODE = e_errcode ;
               
END
$_$ ;

ALTER FUNCTION z_asgard_admin.asgard_on_alter_objet()
    OWNER TO g_admin ;

COMMENT ON FUNCTION z_asgard_admin.asgard_on_alter_objet() IS 'ASGARD. Fonction exécutée par le déclencheur sur évènement asgard_on_alter_objet, qui assure que le producteur d''un schéma reste propriétaire de tous les objets qui en dépendent.' ;


-- Event Trigger: asgard_on_alter_objet

DO
$$
BEGIN
    IF current_setting('server_version_num')::int < 100000
    THEN
        CREATE EVENT TRIGGER asgard_on_alter_objet ON DDL_COMMAND_END
            WHEN TAG IN ('ALTER TABLE', 'ALTER VIEW',
                'ALTER MATERIALIZED VIEW', 'ALTER SEQUENCE', 'ALTER FOREIGN TABLE',
                'ALTER FUNCTION', 'ALTER OPERATOR', 'ALTER AGGREGATE', 'ALTER COLLATION',
                'ALTER CONVERSION', 'ALTER DOMAIN', 'ALTER TEXT SEARCH CONFIGURATION',
                'ALTER TEXT SEARCH DICTIONARY', 'ALTER TYPE', 'ALTER OPERATOR CLASS',
                'ALTER OPERATOR FAMILY')
            EXECUTE PROCEDURE z_asgard_admin.asgard_on_alter_objet() ;
    ELSIF current_setting('server_version_num')::int < 110000
    THEN
        -- + ALTER STATISTICS, ALTER OPERATOR CLASS, ALTER OPERATOR FAMILY
        CREATE EVENT TRIGGER asgard_on_alter_objet ON DDL_COMMAND_END
            WHEN TAG IN ('ALTER TABLE', 'ALTER VIEW',
                'ALTER MATERIALIZED VIEW', 'ALTER SEQUENCE', 'ALTER FOREIGN TABLE',
                'ALTER FUNCTION', 'ALTER OPERATOR', 'ALTER AGGREGATE', 'ALTER COLLATION',
                'ALTER CONVERSION', 'ALTER DOMAIN', 'ALTER TEXT SEARCH CONFIGURATION',
                'ALTER TEXT SEARCH DICTIONARY', 'ALTER TYPE', 'ALTER OPERATOR CLASS',
                'ALTER OPERATOR FAMILY', 'ALTER STATISTICS')
            EXECUTE PROCEDURE z_asgard_admin.asgard_on_alter_objet() ;
    ELSE
        -- + ALTER PROCEDURE, ALTER ROUTINE
        CREATE EVENT TRIGGER asgard_on_alter_objet ON DDL_COMMAND_END
            WHEN TAG IN ('ALTER TABLE', 'ALTER VIEW',
                'ALTER MATERIALIZED VIEW', 'ALTER SEQUENCE', 'ALTER FOREIGN TABLE',
                'ALTER FUNCTION', 'ALTER OPERATOR', 'ALTER AGGREGATE', 'ALTER COLLATION',
                'ALTER CONVERSION', 'ALTER DOMAIN', 'ALTER TEXT SEARCH CONFIGURATION',
                'ALTER TEXT SEARCH DICTIONARY', 'ALTER TYPE', 'ALTER OPERATOR CLASS',
                'ALTER OPERATOR FAMILY', 'ALTER STATISTICS', 'ALTER PROCEDURE',
                'ALTER ROUTINE')
            EXECUTE PROCEDURE z_asgard_admin.asgard_on_alter_objet() ;
    END IF ;
END
$$ ;

COMMENT ON EVENT TRIGGER asgard_on_alter_objet IS 'ASGARD. Déclencheur sur évènement qui assure que le producteur d''un schéma reste propriétaire de tous les objets qui en dépendent.' ;


-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


---------------------------------------------
------ 5 - TRIGGERS SUR GESTION_SCHEMA ------
---------------------------------------------
/* 5.1 - TRIGGER BEFORE
   5.2 - TRIGGER AFTER
   5.3 - TRIGGER DE GESTION DES PERMISSIONS DE G_ADMIN */
   
------ 5.1 - TRIGGER BEFORE ------

-- Function: z_asgard_admin.asgard_on_modify_gestion_schema_before()

CREATE OR REPLACE FUNCTION z_asgard_admin.asgard_on_modify_gestion_schema_before()
    RETURNS trigger
    LANGUAGE plpgsql
    AS $_$
/* Fonction exécutée par le déclencheur asgard_on_modify_gestion_schema_before
   sur z_asgard_admin.gestion_schema, qui valide et normalise les informations
   saisies dans la table de gestion avant leur enregistrement.

    Raises
    ------
    insufficient_privilege
        TB1. Si un utilisateur tente d'ajouter des enregistrements à la table
        de gestion alors qu'il ne dispose pas du privilège CREATE sur la base.
        TB18. Si un utilisateur qui n'est pas membre de g_admin tente de modifier
        la valeur du champ "nomenclature" ou, pour les schémas de la nomenclature,
        les champs "bloc", "niv1", "niv1_abr", "niv2", "niv2_abr" et/ou "nom_schema".
        TB19. Si un utilisateur non membre de g_admin tente d'ajouter un
        enregistrement identifié comme schéma appartenant à la nomenclature.
    raise_exception
        TB2. En cas de tentative de suppression d'un enregistrement de la table
        de gestion qui correspond à un schéma actif sans utiliser la fonction
        de déréférencement.
        TB3. En cas de tentative de suppression d'un enregistrement de la table
        de gestion qui correspond à un schéma inactif mais appartenant à la
        nomenclature nationale.
        TB4. Lorsque le champ "creation" passe de True à False alors que le
        schéma existe toujours et n'est pas à la corbeille (bloc "d").
        TB17. Lorsque la valeur du champ de contrôle "ctrl" est invalide,
        dans le cas d'un déréférencement de schéma.
        TB26. En cas de tentative de déréférencement d'un schéma de la
        nomenclature nationale.
        TB27. En cas de tentative de référencement d'un schéma système.
    not_null_violation
        TB8. Si le champ "nom_schema" n'est pas renseigné.
    unique_violation
        TB9 et TB10. Si un schéma de même nom est déjà référencé dans la
        table de gestion.
        TB11 et TB12. Si un schéma de même OID est déjà référencé dans la 
        table de gestion.
    check_violation
        TB13. Si les rôles producteur, éditeur et lecteur ne sont pas distincts.
        TB14 à TB16. Si le bloc est renseigné et n'est pas une lettre minuscule.

    Version notes
    -------------
    v1.5.0
        (M) Suppression des contrôles d'habilitation de l'utilisateur à 
            modifier les schémas des super-utilisateurs. Ils sont
            désormais réalisés par asgard_cherche_executant, appelée par 
            la fonction asgard_on_modify_gestion_schema_after préalablement 
            à la réalisation de chaque action.
        (M) Recours à asgard_cherche_executant pour trouver un 
            rôle habilité à supprimer le schéma, le cas échéant.
        (m) Recours à la fonction asgard_est_schema_systeme pour connaître
            les schémas système dont le référencement est interdit, 
            au lieu d'une liste en dur.
        (m) Recours à asgard_est_actif et asgard_est_reference (version 
            nom et OID) pour différents tests visant à déterminer si le
            schéma est déjà référencé.
        (m) Amélioration de la gestion des messages d'erreur.
        (d) Enrichissement du descriptif.

*/
DECLARE
    n_role text ;
    executant text ;
    utilisateur text := current_user ;
    e_mssg text ;
    e_hint text ;
    e_detl text ;
    e_errcode text ;
    e_schema text ;
BEGIN
    
    ------ INSERT PAR UN UTILISATEUR NON HABILITE ------
    IF TG_OP = 'INSERT' AND NOT has_database_privilege(current_database(), 'CREATE')
    -- même si creation vaut faux, seul un rôle habilité à créer des
    -- schéma peut ajouter des lignes dans la table de gestion
    THEN
        RAISE EXCEPTION 'TB1. Vous devez être habilité à créer des schémas pour réaliser cette opération.'
            USING ERRCODE = 'insufficient_privilege' ;
    END IF ;
    
    ------ APPLICATION DES VALEURS PAR DEFAUT ------
    -- au tout début car de nombreux tests sont faits par la
    -- suite sur "NOT NEW.creation"
    IF TG_OP IN ('INSERT', 'UPDATE')
    THEN
        NEW.creation := coalesce(NEW.creation, False) ;
        NEW.nomenclature := coalesce(NEW.nomenclature, False) ;
    END IF ;

    ------- SCHEMA DEJA REFERENCE ------
    -- en cas d'INSERT portant sur un schéma actif déjà référencé
    -- dans la table de gestion, Asgard tente de déréférencer le
    -- schéma pour permettre au référencement de se dérouler sans
    -- erreur
    -- Cette étape vise à éviter des erreurs lors de la restauration
    -- de la table de gestion, notamment dues à des schémas
    -- créés par des extensions qui se trouveraient être ré-activées 
    -- après Asgard au cours du processus de restauration. Le déclencheur 
    -- asgard_on_schema_create étant alors actif, il provoque l'ajout 
    -- d'un enregistrement pour le schéma dans la table de gestion, ce qui -
    -- si le schéma était initialement référencé - provoquera un conflit 
    -- lors de l'exécution de la commande INSERT qui restaurera l'ancien 
    -- enregistrement de la table de gestion correspondant au schéma (lequel
    -- porte toutes les informations pertinentes sur son éditeur, lecteur, etc.).
    -- Les schémas standards sont recréés avant l'activation des extensions, 
    -- et donc alors que le déclencheur asgard_on_schema_create n'existe pas encore.
    -- La restauration étant nécessairement réalisée par un super-utilisateur,
    -- on ne considère ici que le cas d'un rôle qui hérite au moins des privilèges
    -- de g_admin, condition nécessaire pour déréférencer un schéma avec
    -- asgard_sortie_gestion_schema. 
    IF TG_OP = 'INSERT' AND pg_has_role('g_admin', 'USAGE')
    THEN
        IF NEW.creation AND z_asgard.asgard_est_actif(NEW.nom_schema)
        THEN
            RAISE NOTICE 'Le schéma % est déjà référencé dans la table de gestion. Tentative de dé-référencement préalable.', 
                NEW.nom_schema ;
            PERFORM z_asgard_admin.asgard_sortie_gestion_schema(NEW.nom_schema) ;
        END IF ;
    END IF ;
    
    ------ EFFACEMENT D'UN ENREGISTREMENT ------
    IF TG_OP = 'DELETE'
    THEN   
        -- on n'autorise pas l'effacement si creation vaut True
        -- avec une exception pour les commandes envoyées par la fonction
        -- de maintenance asgard_sortie_gestion_schema
        IF OLD.creation AND (OLD.ctrl[1] IS NULL OR NOT OLD.ctrl[1] = 'EXIT')
        THEN
            RAISE EXCEPTION 'TB2. Opération interdite (schéma %). L''effacement n''est autorisé que si creation vaut False.', OLD.nom_schema
                USING HINT = 'Pour déréférencer un schéma sans le supprimer, vous pouvez utiliser la fonction z_asgard_admin.asgard_sortie_gestion_schema.',
                    ERRCODE = 'raise_exception' ;
        END IF;
        
        -- on n'autorise pas l'effacement pour les schémas de la nomenclature
        IF OLD.nomenclature
        THEN
            IF OLD.ctrl[1] = 'EXIT'
            THEN
                RAISE EXCEPTION 'TB26. Opération interdite (schéma %). Le déréférencement n''est pas autorisé pour les schémas de la nomenclature nationale.', OLD.nom_schema
                    USING HINT = 'Si vous tenez à déréférencer ce schéma, basculez préalablement nomenclature sur False.',
                        ERRCODE = 'raise_exception' ;
            ELSE
                RAISE EXCEPTION 'TB3. Opération interdite (schéma %). L''effacement n''est pas autorisé pour les schémas de la nomenclature nationale.', OLD.nom_schema
                    USING HINT = 'Si vous tenez à supprimer de la table de gestion les informations relatives à ce schéma, basculez préalablement nomenclature sur False.',
                        ERRCODE = 'raise_exception' ;
            END IF ;
        END IF ;
    END IF;

    ------ DE-CREATION D'UN SCHEMA ------
    IF TG_OP = 'UPDATE'
    THEN

        -- on teste l'existance du schéma (n_role non nul) et on en profite pour 
        -- récupérer son vrai propriétaire, la validité de OLD.oid_producteur
        -- et, surtout, OLD.producteur, n'étant pas avérée à ce stade.
        SELECT
            pg_roles.rolname
            INTO n_role
            FROM pg_catalog.pg_namespace
                INNER JOIN pg_catalog.pg_roles 
                    ON pg_roles.oid = pg_namespace.nspowner
            WHERE OLD.nom_schema = pg_namespace.nspname ;

        -- si bloc valait déjà d (schéma "mis à la corbeille")
        -- on exécute une commande de suppression du schéma. Toute autre modification sur
        -- la ligne est ignorée.
        IF OLD.bloc = 'd' AND OLD.creation AND NOT NEW.creation AND NEW.ctrl[2] IS NULL
            AND n_role IS NOT NULL
        THEN

            -- choix d'un rôle habilité à exécuter les commandes (sinon
            -- asgard_cherche_executant émet une erreur)
            executant := z_asgard.asgard_cherche_executant(
                'DROP SCHEMA',
                old_producteur := n_role
            ) ;
            EXECUTE format('SET ROLE %I', executant) ;

            EXECUTE format('DROP SCHEMA %I CASCADE', OLD.nom_schema) ;
            RAISE NOTICE '... Le schéma % a été supprimé.', OLD.nom_schema ;

            EXECUTE format('SET ROLE %I', utilisateur) ;

            RETURN NULL ;

        -- sinon, on n'autorise creation à passer de true à false que si le schéma
        -- n'existe plus (permet notamment à l'event trigger qui gère les
        -- suppressions de mettre creation à false)
        ELSIF OLD.creation and NOT NEW.creation
                AND NEW.nom_schema IN (SELECT nspname FROM pg_catalog.pg_namespace)
        THEN
            RAISE EXCEPTION 'TB4. Opération interdite (schéma %). Le champ creation ne peut passer de True à False si le schéma existe et n''est pas à la corbeille (bloc "d").', NEW.nom_schema
                USING HINT =  'Si vous supprimez physiquement le schéma avec la commande DROP SCHEMA, creation basculera sur False automatiquement.',
                    ERRCODE = 'raise_exception' ;
        END IF ;
    END IF ;
    
    IF TG_OP <> 'DELETE'
    THEN
        ------ PROHIBITION DE LA SAISIE MANUELLE DES OID ------
        -- vérifié grâce au champ ctrl
        IF NEW.ctrl[2] IS NULL
            OR NOT array_length(NEW.ctrl, 1) >= 2
            OR NEW.ctrl[1] IS NULL
            OR NOT NEW.ctrl[1] IN ('CREATE', 'RENAME', 'OWNER', 'DROP', 'SELF', 'EXIT', 'END')
            OR NOT NEW.ctrl[2] = 'x7-A;#rzo'
            -- ctrl NULL ou invalide
        THEN

            IF NEW.ctrl[1] = 'EXIT'
            THEN
                RAISE EXCEPTION 'TB17. Opération interdite (schéma %).', coalesce(NEW.nom_schema, '?')
                    USING HINT = 'Pour déréférencer un schéma, veuillez utiliser la fonction z_asgard_admin.asgard_sortie_gestion_schema.' ;
            END IF ;
            
            -- réinitialisation du champ ctrl, qui peut contenir des informations
            -- issues de commandes antérieures (dans ctrl[1])
            NEW.ctrl := ARRAY['MANUEL', NULL]::text[] ;
            
            IF TG_OP = 'INSERT' AND (
                    NEW.oid_producteur IS NOT NULL
                    OR NEW.oid_lecteur IS NOT NULL
                    OR NEW.oid_editeur IS NOT NULL
                    OR NEW.oid_schema IS NOT NULL
                    )
            -- cas d'un INSERT manuel pour lequel des OID ont été saisis
            -- on les remet à NULL
            THEN
                NEW.oid_producteur = NULL ;
                NEW.oid_editeur = NULL ;
                NEW.oid_lecteur = NULL ;
                NEW.oid_schema = NULL ;
            ELSIF TG_OP = 'UPDATE'
            THEN
                IF NOT coalesce(NEW.oid_producteur, -1) = coalesce(OLD.oid_producteur, -1)
                        OR NOT coalesce(NEW.oid_editeur, -1) = coalesce(OLD.oid_editeur, -1)
                        OR NOT coalesce(NEW.oid_lecteur, -1) = coalesce(OLD.oid_lecteur, -1)
                        OR NOT coalesce(NEW.oid_schema, -1) = coalesce(OLD.oid_schema, -1)
                -- cas d'un UPDATE avec modification des OID
                -- on les remet à OLD
                THEN
                    NEW.oid_producteur = OLD.oid_producteur ;
                    NEW.oid_editeur = OLD.oid_editeur ;
                    NEW.oid_lecteur = OLD.oid_lecteur ;
                    NEW.oid_schema = OLD.oid_schema ;
                END IF ;
            END IF ;                
        ELSE
            -- suppression du mot de passe de contrôle.
            -- ctrl[1] est par contre conservé - il sera utilisé
            -- par le trigger AFTER pour connaître l'opération
            -- à l'origine de son déclenchement.
            NEW.ctrl[2] := NULL ;
        END IF ;
        
        ------ REQUETES AUTO A IGNORER ------
        -- les remontées du trigger AFTER (SELF ou END)
        -- sont exclues, car les contraintes ont déjà
        -- été validées (et pose problèmes avec les
        -- contrôles d'OID sur les UPDATE, car ceux-ci
        -- ne seront pas nécessairement déjà remplis) ;
        -- les requêtes EXIT de même, car c'est un
        -- pré-requis à la suppression qui ne fait
        -- que modifier le champ ctrl
        IF NEW.ctrl[1] IN ('SELF', 'EXIT', 'END')
        THEN
            -- aucune action
            RETURN NEW ;
        END IF ;
        
        ------ VERROUILLAGE DES CHAMPS LIES A LA NOMENCLATURE ------
        -- modifiables uniquement par l'ADL
        IF TG_OP = 'UPDATE'
        THEN
            IF (OLD.nomenclature OR NEW.nomenclature) AND NOT pg_has_role('g_admin', 'MEMBER') AND (
                    NOT coalesce(OLD.nomenclature, False) = coalesce(NEW.nomenclature, False)
                    OR NOT coalesce(OLD.niv1, '') = coalesce(NEW.niv1, '')
                    OR NOT coalesce(OLD.niv1_abr, '') = coalesce(NEW.niv1_abr, '')
                    OR NOT coalesce(OLD.niv2, '') = coalesce(NEW.niv2, '')
                    OR NOT coalesce(OLD.niv2_abr, '') = coalesce(NEW.niv2_abr, '')
                    OR NOT coalesce(OLD.nom_schema, '') = coalesce(NEW.nom_schema, '')
                    OR NOT coalesce(OLD.bloc, '') = coalesce(NEW.bloc, '')
                    )
            THEN
                RAISE EXCEPTION 'TB18. Opération interdite (schéma %).', NEW.nom_schema
                    USING DETAIL = 'Seuls les membres de g_admin sont habilités à modifier les champs nomenclature et - pour les schémas de la nomenclature - bloc, niv1, niv1_abr, niv2, niv2_abr et nom_schema.',
                        ERRCODE = 'insufficient_privilege' ;
            END IF ;
        ELSIF TG_OP = 'INSERT'
        THEN
            IF NEW.nomenclature AND NOT pg_has_role('g_admin', 'MEMBER')
            THEN
                RAISE EXCEPTION 'TB19. Opération interdite (schéma %).', NEW.nom_schema
                    USING DETAIL = 'Seuls les membres de g_admin sont autorisés à ajouter des schémas à la nomenclature (nomenclature = True).',
                        ERRCODE = 'insufficient_privilege' ;
            END IF ;
        END IF ;
    
        ------ NETTOYAGE DES CHAÎNES VIDES ------
        -- si l'utilisateur a entré des chaînes vides on met des NULL
        NEW.editeur := nullif(NEW.editeur, '') ;
        NEW.lecteur := nullif(NEW.lecteur, '') ;
        NEW.bloc := nullif(NEW.bloc, '') ;
        NEW.niv1 := nullif(NEW.niv1, '') ;
        NEW.niv1_abr := nullif(NEW.niv1_abr, '') ;
        NEW.niv2 := nullif(NEW.niv2, '') ;
        NEW.niv2_abr := nullif(NEW.niv2_abr, '') ;
        NEW.nom_schema := nullif(NEW.nom_schema, '') ;
        -- si producteur est vide on met par défaut g_admin
        NEW.producteur := coalesce(nullif(NEW.producteur, ''), 'g_admin') ;
        
        ------ NETTOYAGE DES CHAMPS OID ------
        -- pour les rôles de lecteur et éditeur,
        -- si le champ de nom est vidé par l'utilisateur,
        -- on vide en conséquence l'OID
        IF NEW.editeur IS NULL
        THEN
            NEW.oid_editeur := NULL ;
        END IF ;
        IF NEW.lecteur IS NULL
        THEN
            NEW.oid_lecteur := NULL ;
        END IF ;
        -- si le schéma n'est pas créé, on s'assure que les champs
        -- d'OID restent vides
        -- à noter que l'event trigger sur DROP SCHEMA vide
        -- déjà le champ oid_schema
        IF NOT NEW.creation
        THEN
            NEW.oid_schema := NULL ;
            NEW.oid_lecteur := NULL ;
            NEW.oid_editeur := NULL ;
            NEW.oid_producteur := NULL ;
        END IF ;
        
        ------ VALIDITE DES NOMS DE ROLES ------
        -- dans le cas d'un schéma pré-existant, on s'assure que les rôles qui
        -- ne changent pas sont toujours valides (qu'ils existent et que le nom
        -- n'a pas été modifié entre temps)
        -- si tel est le cas, on les met à jour et on le note dans
        -- ctrl, pour que le trigger AFTER sache qu'il ne s'agit
        -- pas réellement de nouveaux rôles sur lesquels les droits
        -- devraient être réappliqués
        IF TG_OP = 'UPDATE' AND NEW.creation
        THEN
            -- producteur
            IF OLD.creation AND OLD.producteur = NEW.producteur
            THEN
                SELECT rolname INTO n_role
                    FROM pg_catalog.pg_roles
                    WHERE pg_roles.oid = NEW.oid_producteur ;
                IF NOT FOUND
                -- le rôle producteur n'existe pas
                THEN
                    -- cas invraisemblable, car un rôle ne peut pas être
                    -- supprimé alors qu'il est propriétaire d'un schéma, et la
                    -- commande ALTER SCHEMA OWNER TO aurait été interceptée
                    -- mais, s'il advient, on repart du propriétaire
                    -- renseigné dans pg_namespace
                    SELECT rolname, nspowner
                        INTO NEW.producteur, NEW.oid_producteur
                        FROM pg_catalog.pg_namespace
                            LEFT JOIN pg_catalog.pg_roles ON pg_roles.oid = nspowner
                        WHERE pg_namespace.oid = NEW.oid_schema ;
                    RAISE NOTICE '[table de gestion] ANOMALIE. Schéma %. L''OID actuellement renseigné pour le producteur est invalide. Poursuite avec l''OID du propriétaire courant du schéma.', NEW.nom_schema ;
                    NEW.ctrl := array_append(NEW.ctrl, 'CLEAN producteur') ;
                ELSIF NOT n_role = NEW.producteur
                -- libellé obsolète du producteur
                THEN
                    NEW.producteur := n_role ;
                    RAISE NOTICE '[table de gestion] Schéma %. Mise à jour du libellé du rôle producteur, renommé entre temps.', NEW.nom_schema
                        USING DETAIL = format('Ancien nom "%s", nouveau nom "%s".', OLD.producteur, NEW.producteur) ;
                    NEW.ctrl := array_append(NEW.ctrl, 'CLEAN producteur') ;
                END IF ; 
            END IF ;
            -- éditeur
            IF OLD.creation AND OLD.editeur = NEW.editeur
                    AND NOT NEW.editeur = 'public'
            THEN
                SELECT rolname INTO n_role
                    FROM pg_catalog.pg_roles
                    WHERE pg_roles.oid = NEW.oid_editeur ;
                IF NOT FOUND
                -- le rôle éditeur n'existe pas
                THEN
                    NEW.editeur := NULL ;
                    NEW.oid_editeur := NULL ;
                    RAISE NOTICE '[table de gestion] Schéma %. Le rôle éditeur n''existant plus, il est déréférencé.', NEW.nom_schema
                        USING DETAIL = format('Ancien nom "%s".', OLD.editeur) ;
                    NEW.ctrl := array_append(NEW.ctrl, 'CLEAN editeur') ;
                ELSIF NOT n_role = NEW.editeur
                -- libellé obsolète de l'éditeur
                THEN
                    NEW.editeur := n_role ;
                    RAISE NOTICE '[table de gestion] Schéma %. Mise à jour du libellé du rôle éditeur, renommé entre temps.', NEW.nom_schema
                        USING DETAIL = format('Ancien nom "%s", nouveau nom "%s".', OLD.editeur, NEW.editeur) ;
                    NEW.ctrl := array_append(NEW.ctrl, 'CLEAN editeur') ;
                END IF ; 
            END IF ;
            -- lecteur
            IF OLD.creation AND OLD.lecteur = NEW.lecteur
                    AND NOT NEW.lecteur = 'public'
            THEN
                SELECT rolname INTO n_role
                    FROM pg_catalog.pg_roles
                    WHERE pg_roles.oid = NEW.oid_lecteur ;
                IF NOT FOUND
                -- le rôle lecteur n'existe pas
                THEN
                    NEW.lecteur := NULL ;
                    NEW.oid_lecteur := NULL ;
                    RAISE NOTICE '[table de gestion] Schéma %. Le rôle lecteur n''existant plus, il est déréférencé.', NEW.nom_schema
                        USING DETAIL = format('Ancien nom "%s".', OLD.lecteur) ;
                    NEW.ctrl := array_append(NEW.ctrl, 'CLEAN lecteur') ;
                ELSIF NOT n_role = NEW.lecteur
                -- libellé obsolète du lecteur
                THEN
                    NEW.lecteur := n_role ;
                    RAISE NOTICE '[table de gestion] Schéma %. Mise à jour du libellé du rôle lecteur, renommé entre temps.', NEW.nom_schema
                        USING DETAIL = format('Ancien nom "%s", nouveau nom "%s".', OLD.lecteur, NEW.lecteur) ;
                    NEW.ctrl := array_append(NEW.ctrl, 'CLEAN lecteur') ;
                END IF ; 
            END IF ;    
        END IF ;

        ------ NON RESPECT DES CONTRAINTES ------
        -- non nullité de nom_schema
        IF NEW.nom_schema IS NULL
        THEN
            RAISE EXCEPTION 'TB8. Saisie incorrecte. Le nom du schéma doit être renseigné (champ nom_schema).'
                USING ERRCODE = 'not_null_violation' ;
        END IF ;

        -- pas de schéma système
        IF z_asgard.asgard_est_schema_systeme(NEW.nom_schema)
        THEN
            RAISE EXCEPTION 'TB27. Le référencement des schémas système n''est pas autorisé (schéma %).', NEW.nom_schema
                USING ERRCODE = 'raise_exception' ;
        END IF ;
        
        -- unicité de nom_schema
        -- -> contrôlé après les manipulations sur les blocs de
        -- la partie suivante.
        
        -- unicité de oid_schema
        IF TG_OP = 'INSERT' AND z_asgard.asgard_est_reference(NEW.oid_schema)
        THEN
            RAISE EXCEPTION 'TB11. Saisie incorrecte (schéma %). Un schéma de même OID est déjà répertorié dans la table de gestion.', NEW.nom_schema
                USING ERRCODE = 'unique_violation' ;
        ELSIF TG_OP = 'UPDATE'
        THEN
            -- cas (très hypothétique) d'une modification d'OID
            IF NOT coalesce(NEW.oid_schema, -1) = coalesce(OLD.oid_schema, -1)
                AND z_asgard.asgard_est_reference(NEW.oid_schema)
            THEN
                RAISE EXCEPTION 'TB12. Saisie incorrecte (schéma %). Un schéma de même OID est déjà répertorié dans la table de gestion.', NEW.nom_schema
                    USING ERRCODE = 'unique_violation' ;
            END IF ;
        END IF ;
        
        -- non répétition des rôles
        IF NOT (
            (NEW.oid_lecteur IS NULL OR NOT NEW.oid_lecteur = NEW.oid_producteur)
            AND (NEW.oid_editeur IS NULL OR NOT NEW.oid_editeur = NEW.oid_producteur)
            AND (NEW.oid_lecteur IS NULL OR NEW.oid_editeur IS NULL OR NOT NEW.oid_lecteur = NEW.oid_editeur)
        )
        THEN
            RAISE EXCEPTION 'TB13. Saisie incorrecte (schéma %). Les rôles producteur, lecteur et éditeur doivent être distincts.', NEW.nom_schema
                USING ERRCODE = 'check_violation' ;
        END IF ;
    END IF ;
    
    ------ COHERENCE BLOC/NOM DU SCHEMA ------
    IF TG_OP IN ('INSERT', 'UPDATE')
    THEN
        IF NEW.nom_schema ~ '^d_'
        -- cas d'un schéma mis à la corbeille par un changement de nom
        -- on rétablit le nom antérieur, la lettre d apparaissant
        -- exclusivement dans le bloc
        THEN
            IF TG_OP = 'INSERT'
            -- pour un INSERT, on ne s'intéresse qu'aux cas où
            -- le bloc est NULL ou vaut d. Dans tous les autres cas,
            -- le bloc prévaudra sur le nom et le schéma n'ira
            -- pas à la corbeille de toute façon
            THEN
                IF NEW.bloc IS NULL   
                THEN
                    NEW.bloc := 'd' ;
                    RAISE NOTICE USING MESSAGE = format('[table de gestion] Mise à jour du bloc pour le schéma %s (%s).',
                        NEW.nom_schema, NEW.bloc) ;
                    
                    NEW.nom_schema := substring(NEW.nom_schema, '^d_(.*)$') ;
                    RAISE NOTICE '[table de gestion] Le préfixe du schéma % a été supprimé.', NEW.nom_schema ;
                        
                ELSIF NEW.bloc = 'd'
                THEN
                    NEW.nom_schema := substring(NEW.nom_schema, '^d_(.*)$') ;
                    RAISE NOTICE '[table de gestion] Le préfixe du schéma % a été supprimé.', NEW.nom_schema ; 
                END IF ;
            ELSE
            -- pour un UPDATE, on s'intéresse aux cas où le bloc
            -- n'a pas changé et aux cas où il a été mis sur 'd' ou
            -- (sous certaines conditions) sur NULL.
            -- Sinon, le bloc prévaudra sur le nom et le
            -- schéma n'ira pas à la corbeille de toute façon
                IF NEW.bloc = 'd' AND NOT OLD.bloc = 'd'
                -- mise à la corbeille avec action simultanée sur le nom du schéma
                -- et le bloc + s'il y a un ancien bloc récupérable
                THEN
                    NEW.nom_schema := regexp_replace(NEW.nom_schema, '^(d)_', OLD.bloc || '_') ;
                    RAISE NOTICE USING MESSAGE = format('[table de gestion] Restauration du préfixe du schéma %s d''après son ancien bloc (%s).',
                        NEW.nom_schema, OLD.bloc) ;
                    -- on ne reprend pas l'ancien nom au cas où autre chose que le préfixe aurait été
                    -- changé.
                    
                ELSIF NEW.bloc IS NULL AND NOT OLD.bloc = 'd'
                -- mise à la corbeille via le nom avec mise à NULL du bloc en
                -- parallèle + s'il y a un ancien bloc récupérable
                THEN
                    NEW.nom_schema := regexp_replace(NEW.nom_schema, '^(d)_', OLD.bloc || '_') ;
                    RAISE NOTICE USING MESSAGE = format('[table de gestion] Restauration du préfixe du schéma %s d''après son ancien bloc (%s).',
                        NEW.nom_schema, OLD.bloc) ;
                
                    NEW.bloc := 'd' ;
                    RAISE NOTICE USING MESSAGE = format('[table de gestion] Mise à jour du bloc pour le schéma %s (%s).',
                        NEW.nom_schema, NEW.bloc) ;
                    
                ELSIF NEW.bloc = 'd' AND OLD.bloc = 'd' 
                    AND OLD.nom_schema ~ '^[a-ce-z]_'
                -- s'il y a un ancien préfixe récupérable (cas d'un
                -- schéma dont on tente de forcer le bloc à d alors
                -- qu'il est déjà dans la corbeille)
                THEN
                    NEW.nom_schema := regexp_replace(NEW.nom_schema, '^(d)_', substring(OLD.nom_schema, '^([a-ce-z]_)')) ;
                    RAISE NOTICE '[table de gestion] Restauration du préfixe du schéma %.', NEW.nom_schema ;
                    
                ELSIF NEW.bloc = 'd' AND OLD.bloc = 'd' 
                    AND NOT OLD.nom_schema ~ '^[a-z]_'
                -- schéma sans bloc de la corbeille sur lequel on tente de forcer
                -- un préfixe d
                THEN
                    NEW.nom_schema := substring(NEW.nom_schema, '^d_(.*)$') ;
                    RAISE NOTICE '[table de gestion] Suppression du préfixe du schéma sans bloc %.', NEW.nom_schema ;
                
                ELSIF NEW.bloc IS NULL AND OLD.bloc IS NULL
                -- mise à la corbeille d'un schéma sans bloc
                THEN
                    NEW.bloc := 'd' ;
                    RAISE NOTICE USING MESSAGE = format('[table de gestion] Mise à jour du bloc pour le schéma %s (%s).',
                        NEW.nom_schema, NEW.bloc) ;
                    
                    NEW.nom_schema := substring(NEW.nom_schema, '^d_(.*)$') ;
                    RAISE NOTICE '[table de gestion] Le préfixe du schéma % a été supprimé.', NEW.nom_schema ;
                        
                ELSIF NEW.bloc = 'd' AND OLD.bloc IS NULL
                -- mise à la corbeille d'un schéma sans bloc
                -- avec modification simultanée du nom et du bloc
                THEN
                    NEW.nom_schema := substring(NEW.nom_schema, '^d_(.*)$') ;
                    RAISE NOTICE '[table de gestion] Le préfixe du schéma % a été supprimé.', NEW.nom_schema ;
                    
                ELSIF NEW.bloc = OLD.bloc AND NOT NEW.bloc = 'd'
                -- le bloc ne change pas et contenait une autre
                -- valeur que d
                THEN
                    NEW.nom_schema := regexp_replace(NEW.nom_schema, '^(d)_', OLD.bloc || '_') ;
                    RAISE NOTICE USING MESSAGE = format('[table de gestion] Restauration du préfixe du schéma %s d''après son ancien bloc (%s).',
                        NEW.nom_schema, OLD.bloc) ;
                    
                    NEW.bloc := 'd' ;
                    RAISE NOTICE USING MESSAGE = format('[table de gestion] Mise à jour du bloc pour le schéma %s (%s).',
                        NEW.nom_schema, NEW.bloc) ;
                END IF ;
                
            END IF ;
        END IF ;
    END IF ;
    
    IF TG_OP IN ('INSERT', 'UPDATE')
    THEN
        IF NEW.bloc IS NULL AND NEW.nom_schema ~ '^[a-z]_'
        -- si bloc est NULL, mais que le nom du schéma
        -- comporte un préfixe, 
        THEN
            IF TG_OP = 'UPDATE'
            THEN
                IF OLD.bloc IS NOT NULL
                    AND OLD.nom_schema ~ '^[a-z]_'
                    AND left(NEW.nom_schema, 1) = left(OLD.nom_schema, 1)
                -- sur un UPDATE où le préfixe du schéma n'a pas été modifié, tandis
                -- que le bloc a été mis à NULL, on supprime le préfixe du schéma
                THEN
                    NEW.nom_schema := regexp_replace(NEW.nom_schema, '^[a-z]_', '') ;
                    RAISE NOTICE '[table de gestion] Le préfixe du schéma % a été supprimé.', NEW.nom_schema ;
                    RAISE NOTICE '[table de gestion] Le nom du schéma % ne respecte pas la nomenclature.', NEW.nom_schema
                        USING HINT = 'Si vous saisissez un préfixe dans le champ bloc, il sera automatiquement ajouté au nom du schéma.' ;
                ELSE
                -- sinon, on met le préfixe du nom du schéma dans bloc
                    NEW.bloc := substring(NEW.nom_schema, '^([a-z])_') ;
                    RAISE NOTICE USING MESSAGE = format('[table de gestion] Mise à jour du bloc pour le schéma %s (%s).',
                        NEW.nom_schema, NEW.bloc) ;
                END IF ;
            ELSE
                -- sur un INSERT,
                -- on met le préfixe du nom du schéma dans bloc
                NEW.bloc := substring(NEW.nom_schema, '^([a-z])_') ;
                RAISE NOTICE USING MESSAGE = format('[table de gestion] Mise à jour du bloc pour le schéma %s (%s).',
                    NEW.nom_schema, NEW.bloc) ;
            END IF ;
        ELSIF NEW.bloc IS NULL
        -- si bloc est NULL, et que (sous-entendu) le nom du schéma ne
        -- respecte pas la nomenclature, on avertit l'utilisateur
        THEN            
            RAISE NOTICE '[table de gestion] Le nom du schéma % ne respecte pas la nomenclature.', NEW.nom_schema
                USING HINT = 'Si vous saisissez un préfixe dans le champ bloc, il sera automatiquement ajouté au nom du schéma.' ;
        ELSIF NOT NEW.nom_schema ~ ('^'|| NEW.bloc || '_')
            AND NOT NEW.bloc = 'd'
        -- le bloc est renseigné mais le nom du schéma ne correspond pas
        -- (et il ne s'agit pas d'un schéma mis à la corbeille) :
        -- Si le nom est de la forme 'a_...', alors :
        -- - dans le cas d'un UPDATE avec modification du nom
        -- du schéma et pas du bloc, on se fie au nom du schéma
        -- et on change le bloc ;
        -- - si bloc n'est pas une lettre, on renvoie une erreur ;
        -- - dans les autres cas, on se fie au bloc et change le
        -- préfixe.
        -- Si le nom ne comporte pas de préfixe :
        -- - s'il vient d'être sciemment supprimé et que le bloc
        -- n'a pas changé, on supprime le bloc ;
        -- - sinon, si le bloc est une lettre, on l'ajoute au début du
        -- nom (sans doubler l'underscore, si le nom commençait par
        -- un underscore) ;
        -- - sinon on renvoie une erreur.
        THEN
            IF NEW.nom_schema ~ '^([a-z])?_'
            -- si le nom du schéma contient un préfixe valide
            THEN
                IF TG_OP = 'UPDATE'
                -- sur un UPDATE
                THEN
                    IF NOT NEW.nom_schema = OLD.nom_schema AND NEW.bloc = OLD.bloc
                    -- si le bloc est le même, mais que le nom du schéma a été modifié
                    -- on met à jour le bloc selon le nouveau préfixe du schéma
                    THEN
                        NEW.bloc := substring(NEW.nom_schema, '^([a-z])_') ;
                        RAISE NOTICE USING MESSAGE = format('[table de gestion] Mise à jour du bloc pour le schéma %s (%s).',
                            NEW.nom_schema, NEW.bloc) ;
                    ELSIF NOT NEW.bloc ~ '^[a-z]$'
                    -- si le nouveau bloc est invalide, on renvoie une erreur
                    THEN
                        RAISE EXCEPTION 'TB14. Saisie invalide (schéma %). Le bloc doit être une lettre minuscule ou rien.', NEW.nom_schema
                            USING ERRCODE = 'check_violation' ;
                    ELSE
                    -- si le bloc est valide, on met à jour le préfixe du schéma d'après le bloc
                        NEW.nom_schema := regexp_replace(NEW.nom_schema, '^([a-z])?_', NEW.bloc || '_') ;
                        RAISE NOTICE USING MESSAGE = format('[table de gestion] Mise à jour du préfixe du schéma %s d''après son bloc (%s)',
                            NEW.nom_schema, NEW.bloc) ;
                    END IF ;
                ELSIF NOT NEW.bloc ~ '^[a-z]$'
                -- (sur un INSERT)
                -- si le nouveau bloc est invalide,
                -- on renvoie une erreur
                THEN
                    RAISE EXCEPTION 'TB15. Saisie invalide (schéma %). Le bloc doit être une lettre minuscule ou rien.', NEW.nom_schema
                        USING ERRCODE = 'check_violation' ;
                ELSE
                -- (sur un INSERT)
                -- si le bloc est valide, on met à jour le préfixe du schéma d'après le bloc
                    NEW.nom_schema := regexp_replace(NEW.nom_schema, '^([a-z])?_', NEW.bloc || '_') ;
                    RAISE NOTICE USING MESSAGE = format('[table de gestion] Mise à jour du préfixe du schéma %s d''après son bloc (%s)',
                        NEW.nom_schema, NEW.bloc) ;
                END IF ;
            ELSIF NOT NEW.bloc ~ '^[a-z]$'
            -- (si le nom du schéma ne contient pas de préfixe valide)
            -- si le nouveau bloc est invalide, on renvoie une erreur
            THEN
                RAISE EXCEPTION 'TB16. Saisie invalide (schéma %). Le bloc doit être une lettre minuscule ou rien.', NEW.nom_schema
                    USING ERRCODE = 'check_violation' ;
            ELSIF TG_OP = 'UPDATE'
            -- (si le nom du schéma ne contient pas de préfixe valide)
            -- sur un UPDATE
            THEN
                IF NEW.bloc = OLD.bloc
                    AND OLD.nom_schema ~ '^([a-z])?_'
                -- s'il y avait un bloc, mais que le préfixe vient d'être supprimé
                -- dans le nom du schéma : on supprime le bloc
                THEN
                    NEW.bloc := NULL ;
                    RAISE NOTICE '[table de gestion] Le bloc du schéma % a été supprimé.', NEW.nom_schema ;
                    RAISE NOTICE '[table de gestion] Le nom du schéma % ne respecte pas la nomenclature.', NEW.nom_schema
                        USING HINT = 'Si vous saisissez un préfixe dans le champ bloc, il sera automatiquement ajouté au nom du schéma.' ;
                ELSE
                -- sinon, préfixage du schéma selon le bloc
                    NEW.nom_schema := NEW.bloc || '_' || NEW.nom_schema ;
                    RAISE NOTICE USING MESSAGE = format('[table de gestion] Mise à jour du préfixe du schéma %s d''après son bloc (%s)',
                        NEW.nom_schema, NEW.bloc) ;
                END IF ;
            ELSE
            -- sur un INSERT, préfixage du schéma selon le bloc
                NEW.nom_schema := NEW.bloc || '_' || NEW.nom_schema ;
                RAISE NOTICE USING MESSAGE = format('[table de gestion] Mise à jour du préfixe du schéma %s d''après son bloc (%s)',
                    NEW.nom_schema, NEW.bloc) ;
            END IF ;
            -- le trigger AFTER se chargera de renommer physiquement le
            -- schéma d'autant que de besoin
        END IF ;
    END IF ;
    
    ------ NON RESPECT DES CONTRAINTES (SUITE) ------
    -- unicité de nom_schema
    IF TG_OP IN ('INSERT', 'UPDATE')
    THEN
        IF TG_OP = 'INSERT'
            AND z_asgard.asgard_est_reference(NEW.nom_schema)
        THEN
            RAISE EXCEPTION 'TB9. Saisie incorrecte (schéma %). Un schéma de même nom est déjà répertorié dans la table de gestion.', NEW.nom_schema
                USING ERRCODE = 'unique_violation' ;
        ELSIF TG_OP = 'UPDATE'
        THEN
            -- cas d'un changement de nom
            IF NOT NEW.nom_schema = OLD.nom_schema
                AND z_asgard.asgard_est_reference(NEW.nom_schema)
            THEN 
                RAISE EXCEPTION 'TB10. Saisie incorrecte (schéma %). Un schéma de même nom est déjà répertorié dans la table de gestion.', NEW.nom_schema
                    USING ERRCODE = 'unique_violation' ;
            END IF ;
        END IF ;
    END IF ;
    
    ------ MISE À LA CORBEILLE ------
    -- notification de l'utilisateur
    IF TG_OP = 'UPDATE'
    THEN
        -- schéma existant dont bloc bascule sur 'd'
        -- ou schéma créé par bascule de creation sur True dans bloc vaut 'd'
        IF NEW.creation AND NEW.bloc = 'd' AND (NOT OLD.bloc = 'd' OR OLD.bloc IS NULL)
                OR NEW.creation AND NOT OLD.creation AND NEW.bloc = 'd'
        THEN
            RAISE NOTICE '[table de gestion] Le schéma % a été mis à la corbeille (bloc = ''d'').', NEW.nom_schema
                USING HINT = 'Si vous basculez creation sur False, le schéma et son contenu seront automatiquement supprimés.' ;
        -- restauration
        ELSIF NEW.creation AND OLD.bloc = 'd' AND (NOT NEW.bloc = 'd' OR NEW.bloc IS NULL)
        THEN
            RAISE NOTICE '[table de gestion] Le schéma % a été retiré de la corbeille (bloc ne vaut plus ''d'').', NEW.nom_schema ;
        END IF ;
    ELSIF TG_OP = 'INSERT'
    THEN
        -- nouveau schéma dont bloc vaut 'd'
        IF NEW.creation AND NEW.bloc = 'd'
        THEN
            RAISE NOTICE '[table de gestion] Le schéma % a été mis à la corbeille (bloc = ''d'').', NEW.nom_schema
                USING HINT = 'Si vous basculez creation sur False, le schéma et son contenu seront automatiquement supprimés.' ;  
        END IF ;
    END IF ;
    
    ------ RETURN ------
	IF TG_OP IN ('UPDATE', 'INSERT')
    THEN
        RETURN NEW ;
    ELSIF TG_OP = 'DELETE'
    THEN
        RETURN OLD ;
    END IF ;

EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                            e_hint = PG_EXCEPTION_HINT,
                            e_detl = PG_EXCEPTION_DETAIL,
                            e_errcode = RETURNED_SQLSTATE,
                            e_schema = SCHEMA_NAME ;

    IF TG_OP = 'INSERT'
    THEN 
        e_schema := coalesce(nullif(e_schema, ''), NEW.nom_schema, '???') ;
    ELSIF TG_OP = 'UPDATE'
    THEN
        e_schema := coalesce(nullif(e_schema, ''), NEW.nom_schema, OLD.nom_schema, '???') ;
    ELSE
        e_schema := coalesce(nullif(e_schema, ''), OLD.nom_schema, '???') ;
    END IF ;

    RAISE EXCEPTION '%', z_asgard.asgard_prefixe_erreur(e_mssg, 'TB')
        USING DETAIL = e_detl,
            HINT = e_hint,
            SCHEMA = e_schema,
            ERRCODE = e_errcode ;

END
$_$ ;

ALTER FUNCTION z_asgard_admin.asgard_on_modify_gestion_schema_before()
    OWNER TO g_admin ;

COMMENT ON FUNCTION z_asgard_admin.asgard_on_modify_gestion_schema_before() IS 'ASGARD. Fonction exécutée par le déclencheur asgard_on_modify_gestion_schema_before sur z_asgard_admin.gestion_schema, qui valide et normalise les informations saisies dans la table de gestion avant leur enregistrement.' ;


-- Trigger: asgard_on_modify_gestion_schema_before

CREATE TRIGGER asgard_on_modify_gestion_schema_before
    BEFORE INSERT OR DELETE OR UPDATE
    ON z_asgard_admin.gestion_schema
    FOR EACH ROW
    EXECUTE PROCEDURE z_asgard_admin.asgard_on_modify_gestion_schema_before() ;
    
COMMENT ON TRIGGER asgard_on_modify_gestion_schema_before ON z_asgard_admin.gestion_schema IS 'ASGARD. Déclencheur qui valide et normalise les informations saisies dans la table de gestion avant leur enregistrement.' ;
    


------ 5.2 - TRIGGER AFTER ------

-- Function: z_asgard_admin.asgard_on_modify_gestion_schema_after()

CREATE OR REPLACE FUNCTION z_asgard_admin.asgard_on_modify_gestion_schema_after()
    RETURNS trigger
    LANGUAGE plpgsql
    AS $_$
/* Fonction exécutée par le déclencheur asgard_on_modify_gestion_schema_after
   sur z_asgard_admin.gestion_schema, qui répercute physiquement les modifications
   de la table de gestion.

    Cette fonction échouera si l'utilisateur courant ne dispose pas des
    privilèges nécessaires pour réaliser les actions considérées.

    Raises
    ------
    raise_exception
        TA1. Si le schéma est marqué comme actif et qu'il n'existe pas de schéma 
        dont l'identifiant est l'OID référencé dans la table de gestion (valeur 
        à l'issue de l'opération). Il s'agit d'une anomalie critique, qui
        n'est pas censée advenir.

    Version notes
    -------------
    v1.5.0
        (M) Recours à asgard_cherche_executant pour trouver 
            des rôles habilités à lancer les commandes. Précédemment,
            la fonction ne considérait que deux rôles : l'utilisateur
            courant et un éventuel rôle disposant de l'attribut 
            CREATEROLE dont était membre l'utilisateur courant.
            Désormais, tous les rôles dont l'utilisateur courant est
            membre sont susceptibles d'être utilisés s'ils disposent
            des droits requis pour une commande donnée ou peuvent
            être habilités par l'utilisateur courant.
            Les contrôles vérifiant que l'utilisateur courant est
            habilité à exécuter les commandes sont entièrement délégués
            à asgard_cherche_executant.
        (M) Recours à asgard_create_role pour la création des rôles et
            l'attribution de permissions aux rôles créateurs sur les
            rôles qu'ils ont créés. Par défaut, dans les versions de 
            PostgreSQL antérieures à 16, un rôle non super-utilisateur
            est rendu membre avec ADMIN OPTION des rôles producteurs qu'il
            vient de créer. Les six paramètres de configuration createur_[...]
            permettent d'ajuster ce comportement.
        (M) La fonction ne confère plus de permissions sur les rôles
            pré-existants, hormis par l'entremise de asgard_cherche_executant.
            Celle-ci ne donnant pas arbitrairement des permissions sur
            les producteurs et anciens producteurs à des rôles quelconques
            dotés de l'attribut CREATEROLE comme le faisait auparavant la
            fonction (seulement à g_admin et à des rôles déjà membres du rôle 
            considéré avec l'option ADMIN), des erreurs pour droits
            insuffisants pourraient être émises pour des actions 
            qui étaient auparavant possibles lorsque l'utilisateur courant
            disposait de CREATEROLE.
        (M) Transfert du contrôle des producteurs rôles de connexion à la
            fonction asgard_visibilite_admin_after, exécutée par le 
            déclencheur de même nom sur gestion_schema. Le paramètre
            de configuration autorise_producteur_connexion permet
            désormais de désactiver ce contrôle.
        (m) Amélioration de la gestion des messages d'erreur.
        (m) Petites améliorations de lisibilité du code.
        (d) Enrichissement du descriptif.        

*/
DECLARE
    utilisateur text := current_user ;
    executant text ;
    proprietaire text ;
    e_mssg text ;
    e_detl text ;
    e_hint text ;
    e_schema text ;
    e_errcode text ;
    all_is_well boolean ;
    l_commande text[] ;
    c text ;
    c_reverse text ;
    a_producteur text ;
    a_editeur text ;
    a_lecteur text ;
    n int ;
BEGIN

    ------ REQUETES AUTO A IGNORER ------
    -- les remontées du trigger lui-même (SELF ou END),
    -- ainsi que des event triggers sur les
    -- suppressions de schémas (DROP), n'appellent
    -- aucune action, elles sont donc exclues dès
    -- le départ
    -- les remontées des changements de noms sont
    -- conservées, pour le cas où la mise en
    -- cohérence avec "bloc" aurait conduit à une
    -- modification du nom par le trigger BEFORE
    -- (géré au point suivant)
    -- les remontées des créations et changements
    -- de propriétaire (CREATE et OWNER) appellent
    -- des opérations sur les droits plus lourdes
    -- qui ne permettent pas de les exclure en
    -- amont
    IF NEW.ctrl[1] IN ('SELF', 'END', 'DROP')
    THEN
        -- aucune action
        RETURN NULL ;
    END IF ;

    ------ MANIPULATIONS PREALABLES ------    
    IF TG_OP = 'UPDATE'
    THEN
        -- la validité de OLD.producteur n'ayant
        -- pas été contrôlée par le trigger BEFORE,
        -- on le fait maintenant
        SELECT rolname INTO a_producteur
            FROM pg_catalog.pg_roles
            WHERE pg_roles.oid = OLD.oid_producteur ;
        -- pour la suite, on emploira toujours
        -- a_producteur à la place de OLD.producteur
        -- pour les opérations sur les droits.
        -- Il est réputé non NULL pour un schéma
        -- pré-existant (OLD.creation vaut True),
        -- dans la mesure où un rôle ne peut être
        -- supprimé s'il est propriétaire d'un
        -- schéma et où tous les changements de
        -- propriétaires sont remontés par event
        -- triggers (+ contrôles pour assurer la
        -- non-modification manuelle des OID).
        IF NOT FOUND AND OLD.creation AND (
            NEW.ctrl IS NULL OR NOT 'CLEAN producteur' = ANY(array_remove(NEW.ctrl, NULL))
        )
        THEN
            RAISE NOTICE '[table de gestion] ANOMALIE. Schéma %. L''OID actuellement renseigné pour le producteur dans la table de gestion est invalide. Poursuite avec l''OID du propriétaire courant du schéma.', OLD.nom_schema ;
            SELECT rolname INTO a_producteur
                FROM pg_catalog.pg_namespace
                    LEFT JOIN pg_catalog.pg_roles ON pg_roles.oid = nspowner
                WHERE pg_namespace.oid = NEW.oid_schema ;
            IF NOT FOUND
            THEN
                RAISE EXCEPTION 'TA1. Anomalie critique. Le schéma d''OID % est introuvable.', NEW.oid_schema
                    USING ERRCODE = 'raise_exception' ;
            END IF ;
        END IF ;
    END IF ;

    ------ MISE EN APPLICATION D'UN CHANGEMENT DE NOM DE SCHEMA ------
    IF NOT NEW.oid_schema::regnamespace::text = quote_ident(NEW.nom_schema)
    -- le schéma existe et ne porte pas déjà le nom NEW.nom_schema
    THEN

        SELECT pg_roles.rolname 
            INTO proprietaire
            FROM pg_catalog.pg_namespace
                INNER JOIN pg_catalog.pg_roles 
                    ON pg_namespace.nspowner = pg_roles.oid
            WHERE pg_namespace.oid = NEW.oid_schema ;
        
        -- choix d'un rôle habilité à exécuter les commandes (sinon
        -- asgard_cherche_executant émet une erreur)
        executant := z_asgard.asgard_cherche_executant(
            'ALTER SCHEMA RENAME',
            new_producteur := proprietaire
        ) ;
        EXECUTE format('SET ROLE %I', executant) ;

        EXECUTE format(
            'ALTER SCHEMA %s RENAME TO %I', 
            NEW.oid_schema::regnamespace, 
            NEW.nom_schema
        ) ;
        RAISE NOTICE '... Le schéma % a été renommé.', NEW.nom_schema ;

        EXECUTE format('SET ROLE %I', utilisateur) ;

    END IF ;

    -- exclusion des remontées d'event trigger correspondant
    -- à des changements de noms
    IF NEW.ctrl[1] = 'RENAME'
    THEN

        -- choix d'un rôle habilité à exécuter les commandes (sinon
        -- asgard_cherche_executant émet une erreur)
        -- en principe, le rôle courant devrait toujours disposer
        -- des privilèges nécessaires, sans quoi il n'aurait pas pu lancer
        -- la commande de changement de nom
        executant := z_asgard.asgard_cherche_executant(
            'MODIFY GESTION SCHEMA', new_producteur := NEW.producteur
        ) ;
        EXECUTE format('SET ROLE %I', executant) ;

        -- on signale la fin du traitement, ce qui
        -- va notamment permettre l'exécution de
        -- asgard_visibilite_admin_after
        UPDATE z_asgard.gestion_schema_etr
            SET ctrl = ARRAY['END', 'x7-A;#rzo']
            WHERE nom_schema = NEW.nom_schema ;

        EXECUTE format('SET ROLE %I', utilisateur) ;
        
        RETURN NULL ;
    END IF ;

    ------ PREPARATION DU PRODUCTEUR ------
    -- on ne s'intéresse pas aux cas :
    -- - d'un schéma qui n'a pas/plus vocation à exister
    --   (creation vaut False) ;
    -- - d'un schéma pré-existant dont les rôles ne changent pas
    --   ou dont le libellé a juste été nettoyé par le trigger
    --   BEFORE.
    -- ils sont donc exclus au préalable
    -- si le moindre rôle a changé, il faudra être membre du
    -- groupe propriétaire/producteur pour pouvoir modifier
    -- les privilèges en conséquence
    all_is_well := False ;
    IF NOT NEW.creation
    THEN
        all_is_well := True ;
    ELSIF TG_OP = 'UPDATE'
    THEN
        IF OLD.creation
                AND (NEW.producteur = OLD.producteur  OR 'CLEAN producteur' = ANY(array_remove(NEW.ctrl, NULL)))
                AND (coalesce(NEW.editeur, '') = coalesce(OLD.editeur, '') OR 'CLEAN editeur' = ANY(array_remove(NEW.ctrl, NULL)))
                AND (coalesce(NEW.lecteur, '') = coalesce(OLD.lecteur, '') OR 'CLEAN lecteur' = ANY(array_remove(NEW.ctrl, NULL)))
        THEN
            all_is_well := True ;
        END IF ;
    END IF ;
    
    IF NOT all_is_well
    THEN

        IF NOT NEW.producteur IN (SELECT rolname FROM pg_catalog.pg_roles)
        -- si le producteur désigné n'existe pas, on le crée
        -- ou renvoie une erreur si les privilèges de l'utilisateur
        -- sont insuffisants
        THEN
            -- asgard_create_role s'occupe de choisir le bon rôle
            -- pour exécuter les commandes et de conférer au rôle créateur
            -- les permissions pertinentes sur le nouveau rôle
            PERFORM z_asgard.asgard_create_role(
                NEW.producteur,
                grant_role_to_createur := True,
                with_admin_option := NOT z_asgard.asgard_parametre('createur_sans_admin_option_producteurs'),
                with_set_inherit_option := True
            ) ;

        END IF ;
        
        -- mise à jour du champ d'OID du producteur
        IF NEW.ctrl[1] IS NULL OR NOT NEW.ctrl[1] IN ('OWNER', 'CREATE')
        -- pas dans le cas d'une remontée de commande directe
        -- où l'OID du producteur sera déjà renseigné
        -- et uniquement s'il a réellement été modifié (ce
        -- qui n'est pas le cas si les changements ne portent
        -- que sur les rôles lecteur/éditeur)
        THEN

            -- choix d'un rôle habilité à exécuter les commandes (sinon
            -- asgard_cherche_executant émet une erreur)
            -- notamment dans le cas où le producteur vient d'être créé
            -- ou modifié et un attribut NOINHERIT ou WITH INHERIT False 
            -- fait que le rôle courant n'a pas immédiatement accès à ses 
            -- privilèges
            executant := z_asgard.asgard_cherche_executant(
                'MODIFY GESTION SCHEMA', new_producteur := NEW.producteur
            ) ;
            EXECUTE format('SET ROLE %I', executant) ;

            UPDATE z_asgard.gestion_schema_etr
                SET oid_producteur = quote_ident(NEW.producteur)::regrole::oid,
                    ctrl = ARRAY['SELF', 'x7-A;#rzo']
                WHERE nom_schema = NEW.nom_schema AND (
                    oid_producteur IS NULL
                    OR NOT oid_producteur = quote_ident(NEW.producteur)::regrole::oid
                    ) ;

            EXECUTE format('SET ROLE %I', utilisateur) ;

        END IF ;
    END IF ;

    ------ PREPARATION DE L'EDITEUR ------
    -- limitée ici à la création du rôle et l'implémentation
    -- de son OID. On ne s'intéresse donc pas aux cas :
    -- - où il y a pas d'éditeur ;
    -- - d'un schéma qui n'a pas/plus vocation à exister ;
    -- - d'un schéma pré-existant dont l'éditeur ne change pas
    --   ou dont le libellé a seulement été nettoyé par le
    --   trigger BEFORE.
    -- ils sont donc exclus au préalable
    all_is_well := False ;
    IF NOT NEW.creation OR NEW.editeur IS NULL
            OR 'CLEAN editeur' = ANY(array_remove(NEW.ctrl, NULL))
    THEN
        all_is_well := True ;
    ELSIF TG_OP = 'UPDATE'
    THEN
        IF OLD.creation AND NEW.editeur = OLD.editeur
        THEN
            all_is_well := True ;           
        END IF ;
    END IF ;
    
    IF NOT all_is_well
    THEN
        IF NOT NEW.editeur IN (SELECT rolname FROM pg_catalog.pg_roles)
                AND NOT NEW.editeur = 'public'
        -- si l'éditeur désigné n'existe pas, on le crée
        -- ou renvoie une erreur si les privilèges de l'utilisateur
        -- sont insuffisants
        THEN
            -- asgard_create_role s'occupe de choisir le bon rôle
            -- pour exécuter les commandes et de conférer au rôle créateur
            -- les permissions pertinentes sur le nouveau rôle
            PERFORM z_asgard.asgard_create_role(
                NEW.editeur,
                grant_role_to_createur := z_asgard.asgard_parametre('createur_avec_permission_editeurs_lecteurs'),
                with_admin_option := z_asgard.asgard_parametre('createur_avec_admin_option_editeurs_lecteurs'),
                with_set_inherit_option := z_asgard.asgard_parametre('createur_avec_set_inherit_option_editeurs_lecteurs')
            ) ;

        END IF ;

        -- choix d'un rôle habilité à exécuter les commandes (sinon
        -- asgard_cherche_executant émet une erreur)
        executant := z_asgard.asgard_cherche_executant(
            'MODIFY GESTION SCHEMA', new_producteur := NEW.producteur
        ) ;
        EXECUTE format('SET ROLE %I', executant) ;
        
        -- mise à jour du champ d'OID de l'éditeur
        IF NEW.editeur = 'public'
        THEN
            
            UPDATE z_asgard.gestion_schema_etr
                SET oid_editeur = 0,
                    ctrl = ARRAY['SELF', 'x7-A;#rzo']
                WHERE nom_schema = NEW.nom_schema AND (
                    oid_editeur IS NULL
                    OR NOT oid_editeur = 0
                    ) ;
        ELSE
            UPDATE z_asgard.gestion_schema_etr
                SET oid_editeur = quote_ident(NEW.editeur)::regrole::oid,
                    ctrl = ARRAY['SELF', 'x7-A;#rzo']
                WHERE nom_schema = NEW.nom_schema AND (
                    oid_editeur IS NULL
                    OR NOT oid_editeur = quote_ident(NEW.editeur)::regrole::oid
                    ) ;
        END IF ;

        EXECUTE format('SET ROLE %I', utilisateur) ;

    END IF ;
    
    ------ PREPARATION DU LECTEUR ------
    -- limitée ici à la création du rôle et l'implémentation
    -- de son OID. On ne s'intéresse donc pas aux cas :
    -- - où il y a pas de lecteur ;
    -- - d'un schéma qui n'a pas/plus vocation à exister ;
    -- - d'un schéma pré-existant dont l'éditeur ne change pas
    --   ou dont le libellé a seulement été nettoyé par le
    --   trigger BEFORE.
    -- ils sont donc exclus au préalable
    all_is_well := False ;
    IF NOT NEW.creation OR NEW.lecteur IS NULL
            OR 'CLEAN lecteur' = ANY(array_remove(NEW.ctrl, NULL))
    THEN
        all_is_well := True ;
    ELSIF TG_OP = 'UPDATE'
    THEN
        IF OLD.creation AND NEW.lecteur = OLD.lecteur
        THEN
            all_is_well := True ;
        END IF ;
    END IF ;
    
    IF NOT all_is_well
    THEN
        IF NOT NEW.lecteur IN (SELECT rolname FROM pg_catalog.pg_roles)
                AND NOT NEW.lecteur = 'public'
        -- si le lecteur désigné n'existe pas, on le crée
        -- ou renvoie une erreur si les privilèges de l'utilisateur
        -- sont insuffisants
        THEN
            -- asgard_create_role s'occupe de choisir le bon rôle
            -- pour exécuter les commandes et de conférer au rôle créateur
            -- les permissions pertinentes sur le nouveau rôle
            PERFORM z_asgard.asgard_create_role(
                NEW.lecteur,
                grant_role_to_createur := z_asgard.asgard_parametre('createur_avec_permission_editeurs_lecteurs'),
                with_admin_option := z_asgard.asgard_parametre('createur_avec_admin_option_editeurs_lecteurs'),
                with_set_inherit_option := z_asgard.asgard_parametre('createur_avec_set_inherit_option_editeurs_lecteurs')
            ) ;

        END IF ;

        -- choix d'un rôle habilité à exécuter les commandes (sinon
        -- asgard_cherche_executant émet une erreur)
        executant := z_asgard.asgard_cherche_executant(
            'MODIFY GESTION SCHEMA', new_producteur := NEW.producteur
        ) ;
        EXECUTE format('SET ROLE %I', executant) ;
        
        -- mise à jour du champ d'OID du lecteur
        IF NEW.lecteur = 'public'
        THEN
            UPDATE z_asgard.gestion_schema_etr
                SET oid_lecteur = 0,
                    ctrl = ARRAY['SELF', 'x7-A;#rzo']
                WHERE nom_schema = NEW.nom_schema AND (
                    oid_lecteur IS NULL
                    OR NOT oid_lecteur = 0
                    ) ;
        ELSE
            UPDATE z_asgard.gestion_schema_etr
                SET oid_lecteur = quote_ident(NEW.lecteur)::regrole::oid,
                    ctrl = ARRAY['SELF', 'x7-A;#rzo']
                WHERE nom_schema = NEW.nom_schema AND (
                    oid_lecteur IS NULL
                    OR NOT oid_lecteur = quote_ident(NEW.lecteur)::regrole::oid
                    ) ;
        END IF ;

        EXECUTE format('SET ROLE %I', utilisateur) ;

    END IF ;
    
    ------ CREATION DU SCHEMA ------
    -- on exclut au préalable les cas qui ne
    -- correspondent pas à des créations, ainsi que les
    -- remontées de l'event trigger sur CREATE SCHEMA,
    -- car le schéma existe alors déjà
    all_is_well := False ;
    IF NOT NEW.creation OR NEW.ctrl[1] = 'CREATE'
    THEN
        all_is_well := True ;
    ELSIF TG_OP = 'UPDATE'
    THEN
        IF OLD.creation
        THEN
            all_is_well := True ;
        END IF ;
    END IF ;
    
    IF NOT all_is_well
    THEN
        -- le schéma est créé s'il n'existe pas déjà (cas d'ajout
        -- d'un schéma pré-existant qui n'était pas référencé dans
        -- gestion_schema jusque-là), sinon on alerte juste
        -- l'utilisateur
        IF NOT NEW.nom_schema IN (SELECT nspname FROM pg_catalog.pg_namespace)
        THEN
            -- choix d'un rôle habilité à exécuter les commandes (sinon
            -- asgard_cherche_executant émet une erreur)
            executant := z_asgard.asgard_cherche_executant(
                'CREATE SCHEMA', new_producteur := NEW.producteur
            ) ;
            EXECUTE format('SET ROLE %I', executant) ;
            EXECUTE format('CREATE SCHEMA %I AUTHORIZATION %I', NEW.nom_schema, NEW.producteur) ;
            EXECUTE format('SET ROLE %I', utilisateur) ;
            RAISE NOTICE '... Le schéma % a été créé.', NEW.nom_schema ;
        ELSE
            RAISE NOTICE '(schéma % pré-existant)', NEW.nom_schema ;
        END IF ;

        -- choix d'un rôle habilité à exécuter les commandes (sinon
        -- asgard_cherche_executant émet une erreur)
        executant := z_asgard.asgard_cherche_executant(
            'MODIFY GESTION SCHEMA', new_producteur := NEW.producteur
        ) ;
        EXECUTE format('SET ROLE %I', executant) ;

        -- récupération de l'OID du schéma
        UPDATE z_asgard.gestion_schema_etr
            SET oid_schema = quote_ident(NEW.nom_schema)::regnamespace::oid,
                ctrl = ARRAY['SELF', 'x7-A;#rzo']
            WHERE nom_schema = NEW.nom_schema AND (
                oid_schema IS NULL
                OR NOT oid_schema = quote_ident(NEW.nom_schema)::regnamespace::oid
                ) ;

        EXECUTE format('SET ROLE %I', utilisateur) ;

    END IF ;
    
    ------ APPLICATION DES DROITS DU PRODUCTEUR ------
    -- comme précédemment pour la préparation du producteur,
    -- on ne s'intéresse pas aux cas :
    -- - d'un schéma qui n'a pas/plus vocation à exister
    --   (creation vaut False) ;
    -- - d'un schéma pré-existant dont le producteur ne change pas
    --   ou dont le libellé a juste été nettoyé par le trigger
    --   BEFORE ;
    -- - d'une remontée de l'event trigger asgard_on_create_schema,
    --   car le producteur sera déjà propriétaire du schéma
    --   et de son éventuel contenu. Par contre on garde les INSERT,
    --   pour les cas de référencements ;
    -- - de z_asgard_admin (pour permettre sa saisie initiale
    --   dans la table de gestion, étant entendu qu'il est
    --   impossible au trigger sur gestion_schema de lancer
    --   un ALTER TABLE OWNER TO sur cette même table).
    -- ils sont donc exclus au préalable
    all_is_well := False ;
    IF NOT NEW.creation
            OR 'CLEAN producteur' = ANY(array_remove(NEW.ctrl, NULL))
            OR NEW.ctrl[1] = 'CREATE'
            OR NEW.nom_schema = 'z_asgard_admin'
    THEN
        all_is_well := True ;
    ELSIF TG_OP = 'UPDATE'
    THEN
        IF OLD.creation AND NEW.producteur = OLD.producteur
        THEN
            all_is_well := True ;
        END IF ;
    END IF ;
    
    -- changements de propriétaires
    IF NOT all_is_well
    THEN

        IF (NEW.nom_schema, quote_ident(NEW.producteur)) IN (
            SELECT
                pg_namespace.nspname,
                pg_namespace.nspowner::regrole::text
                FROM pg_catalog.pg_namespace
        )
        THEN
            -- si producteur est déjà propriétaire du schéma (cas d'une remontée de l'event trigger,
            -- principalement), on ne change que les propriétaires des objets éventuels
            IF quote_ident(NEW.nom_schema)::regnamespace::oid
                    IN (SELECT refobjid FROM pg_catalog.pg_depend WHERE deptype = 'n')
            THEN 
                -- la commande n'est cependant lancée que s'il existe des dépendances de type
                -- DEPENDENCY_NORMAL sur le schéma, ce qui est une condition nécessaire à
                -- l'existence d'objets dans le schéma

                -- pas de changement de rôle, asgard_admin_proprietaire s'en charge
                RAISE NOTICE 'attribution de la propriété des objets au rôle producteur du schéma % :', NEW.nom_schema ;
                SELECT z_asgard.asgard_admin_proprietaire(NEW.nom_schema, NEW.producteur, False)
                    INTO n ;
                IF n = 0
                THEN
                    RAISE NOTICE '> néant' ;
                END IF ; 
            END IF ;
        
        ELSE
            -- sinon schéma + objets

            -- pas de changement de rôle, asgard_admin_proprietaire s'en charge
            RAISE NOTICE 'attribution de la propriété du schéma et des objets au rôle producteur du schéma % :', NEW.nom_schema ;
            PERFORM z_asgard.asgard_admin_proprietaire(NEW.nom_schema, NEW.producteur) ;

        END IF ;
    END IF ;
    
    ------ APPLICATION DES DROITS DE L'EDITEUR ------
    -- on ne s'intéresse pas aux cas :
    -- - d'un schéma qui n'a pas/plus vocation à exister ;
    -- - d'un schéma pré-existant dont l'éditeur ne change pas
    --   (y compris pour rester vide) ou dont le libellé
    --   a seulement été nettoyé par le trigger BEFORE.
    -- ils sont donc exclus au préalable
    all_is_well := False ;
    IF NOT NEW.creation OR 'CLEAN editeur' = ANY(array_remove(NEW.ctrl, NULL))
    THEN
        all_is_well := True ;
    ELSIF TG_OP = 'UPDATE'
    THEN
        IF OLD.creation
            AND coalesce(NEW.editeur, '') = coalesce(OLD.editeur, '')
        THEN
            all_is_well := True ;           
        END IF ;
    END IF ;
    
    IF NOT all_is_well
    THEN
        -- choix d'un rôle habilité à exécuter les commandes (sinon
        -- asgard_cherche_executant émet une erreur)
        executant := z_asgard.asgard_cherche_executant(
            'PRIVILEGES', 
            new_producteur := NEW.producteur
        ) ;
        EXECUTE format('SET ROLE %I', executant) ;
        
        IF TG_OP = 'UPDATE'
        THEN
            -- la validité de OLD.editeur n'ayant
            -- pas été contrôlée par le trigger BEFORE,
            -- on le fait maintenant
            IF OLD.editeur = 'public'
            THEN
                a_editeur := 'public' ;
                -- récupération des modifications manuelles des
                -- droits de OLD.editeur/public, grâce à la fonction
                -- asgard_synthese_public
                SELECT array_agg(commande) INTO l_commande
                    FROM z_asgard.asgard_synthese_public(
                        quote_ident(NEW.nom_schema)::regnamespace
                        ) ;   
            ELSE
                SELECT rolname INTO a_editeur
                    FROM pg_catalog.pg_roles
                    WHERE pg_roles.oid = OLD.oid_editeur ;
                IF FOUND
                THEN
                    -- récupération des modifications manuelles des
                    -- droits de OLD.editeur, grâce à la fonction
                    -- asgard_synthese_role
                    SELECT array_agg(commande) INTO l_commande
                        FROM z_asgard.asgard_synthese_role(
                            quote_ident(NEW.nom_schema)::regnamespace,
                            quote_ident(a_editeur)::regrole
                            ) ;
                END IF ;
            END IF ;
        END IF ;

        IF l_commande IS NOT NULL
        -- transfert sur NEW.editeur des droits de
        -- OLD.editeur, le cas échéant
        THEN
            IF NEW.editeur IS NOT NULL
            THEN
                RAISE NOTICE 'suppression et transfert vers le nouvel éditeur des privilèges de l''ancien éditeur du schéma % :', NEW.nom_schema ;
            ELSE
                RAISE NOTICE 'suppression des privilèges de l''ancien éditeur du schéma % :', NEW.nom_schema ;
            END IF ;
            FOREACH c IN ARRAY l_commande
            LOOP
                IF NEW.editeur IS NOT NULL
                THEN
                    EXECUTE format(c, NEW.editeur) ;
                    RAISE NOTICE '> %', format(c, NEW.editeur) ;
                END IF ;
                IF c ~ '^GRANT'
                THEN
                    SELECT z_asgard.asgard_grant_to_revoke(c) INTO c_reverse ;
                    EXECUTE format(c_reverse, a_editeur) ;
                    RAISE NOTICE '> %', format(c_reverse, a_editeur) ;
                END IF ;
            END LOOP ;
            
        -- sinon, application des privilèges standards de l'éditeur
        ELSIF NEW.editeur IS NOT NULL
        THEN
            RAISE NOTICE 'application des privilèges standards pour le rôle éditeur du schéma % :', NEW.nom_schema ;
            
            EXECUTE format('GRANT USAGE ON SCHEMA %I TO %I', NEW.nom_schema, NEW.editeur) ;
            RAISE NOTICE '> %', format('GRANT USAGE ON SCHEMA %I TO %I', NEW.nom_schema, NEW.editeur) ;
            
            EXECUTE format('GRANT SELECT, UPDATE, DELETE, INSERT ON ALL TABLES IN SCHEMA %I TO %I', NEW.nom_schema, NEW.editeur) ;
            RAISE NOTICE '> %', format('GRANT SELECT, UPDATE, DELETE, INSERT ON ALL TABLES IN SCHEMA %I TO %I', NEW.nom_schema, NEW.editeur) ;
            
            EXECUTE format('GRANT SELECT, USAGE ON ALL SEQUENCES IN SCHEMA %I TO %I', NEW.nom_schema, NEW.editeur) ;
            RAISE NOTICE '> %', format('GRANT SELECT, USAGE ON ALL SEQUENCES IN SCHEMA %I TO %I', NEW.nom_schema, NEW.editeur) ;
            
        END IF ;
        
        EXECUTE format('SET ROLE %I', utilisateur) ;

    END IF ;
    
    ------ APPLICATION DES DROITS DU LECTEUR ------
    -- on ne s'intéresse pas aux cas :
    -- - d'un schéma qui n'a pas/plus vocation à exister ;
    -- - d'un schéma pré-existant dont le lecteur ne change pas
    --   (y compris pour rester vide) ou dont le libellé
    --   a seulement été nettoyé par le trigger BEFORE.
    -- ils sont donc exclus au préalable
    all_is_well := False ;
    l_commande := NULL ;
    IF NOT NEW.creation OR 'CLEAN lecteur' = ANY(array_remove(NEW.ctrl, NULL))
    THEN
        all_is_well := True ;
    ELSIF TG_OP = 'UPDATE'
    THEN
        IF OLD.creation
            AND coalesce(NEW.lecteur, '') = coalesce(OLD.lecteur, '')
        THEN
            all_is_well := True ;           
        END IF ;
    END IF ;
    
    IF NOT all_is_well
    THEN
        
        -- choix d'un rôle habilité à exécuter les commandes (sinon
        -- asgard_cherche_executant émet une erreur)
        executant := z_asgard.asgard_cherche_executant(
            'PRIVILEGES', 
            new_producteur := NEW.producteur
        ) ;
        EXECUTE format('SET ROLE %I', executant) ;
        
        IF TG_OP = 'UPDATE'
        THEN
            -- la validité de OLD.lecteur n'ayant
            -- pas été contrôlée par le trigger BEFORE,
            -- on le fait maintenant
            IF OLD.lecteur = 'public'
            THEN
                a_lecteur := 'public' ;
                -- récupération des modifications manuelles des
                -- droits de OLD.lecteur/public, grâce à la fonction
                -- asgard_synthese_public
                SELECT array_agg(commande) INTO l_commande
                    FROM z_asgard.asgard_synthese_public(
                        quote_ident(NEW.nom_schema)::regnamespace
                        ) ;   
            ELSE
                SELECT rolname INTO a_lecteur
                    FROM pg_catalog.pg_roles
                    WHERE pg_roles.oid = OLD.oid_lecteur ;
                IF FOUND
                THEN
                    -- récupération des modifications manuelles des
                    -- droits de OLD.lecteur, grâce à la fonction
                    -- asgard_synthese_role
                    SELECT array_agg(commande) INTO l_commande
                        FROM z_asgard.asgard_synthese_role(
                            quote_ident(NEW.nom_schema)::regnamespace,
                            quote_ident(a_lecteur)::regrole
                            ) ;
                END IF ;
            END IF ;
        END IF ;

        IF l_commande IS NOT NULL
        -- transfert sur NEW.lecteur des droits de
        -- OLD.lecteur, le cas échéant
        THEN
            IF NEW.lecteur IS NOT NULL
            THEN
                RAISE NOTICE 'suppression et transfert vers le nouveau lecteur des privilèges de l''ancien lecteur du schéma % :', NEW.nom_schema ;
            ELSE
                RAISE NOTICE 'suppression des privilèges de l''ancien lecteur du schéma % :', NEW.nom_schema ;
            END IF ;
            FOREACH c IN ARRAY l_commande
            LOOP
                IF NEW.lecteur IS NOT NULL
                THEN
                    EXECUTE format(c, NEW.lecteur) ;
                    RAISE NOTICE '> %', format(c, NEW.lecteur) ;
                END IF ;
                IF c ~ '^GRANT'
                THEN
                    SELECT z_asgard.asgard_grant_to_revoke(c) INTO c_reverse ;
                    EXECUTE format(c_reverse, a_lecteur) ;
                    RAISE NOTICE '> %', format(c_reverse, a_lecteur) ;
                END IF ;
            END LOOP ;
            
        -- sinon, application des privilèges standards du lecteur
        ELSIF NEW.lecteur IS NOT NULL
        THEN
            RAISE NOTICE 'application des privilèges standards pour le rôle lecteur du schéma % :', NEW.nom_schema ;
            
            EXECUTE format('GRANT USAGE ON SCHEMA %I TO %I', NEW.nom_schema, NEW.lecteur) ;
            RAISE NOTICE '> %', format('GRANT USAGE ON SCHEMA %I TO %I', NEW.nom_schema, NEW.lecteur) ;
            
            EXECUTE format('GRANT SELECT ON ALL TABLES IN SCHEMA %I TO %I', NEW.nom_schema, NEW.lecteur) ;
            RAISE NOTICE '> %', format('GRANT SELECT ON ALL TABLES IN SCHEMA %I TO %I', NEW.nom_schema, NEW.lecteur) ;
            
            EXECUTE format('GRANT SELECT ON ALL SEQUENCES IN SCHEMA %I TO %I', NEW.nom_schema, NEW.lecteur) ;
            RAISE NOTICE '> %', format('GRANT SELECT ON ALL SEQUENCES IN SCHEMA %I TO %I', NEW.nom_schema, NEW.lecteur) ;
            
        END IF ;
        
        EXECUTE format('SET ROLE %I', utilisateur) ;

    END IF ;

    -- choix d'un rôle habilité à exécuter les commandes (sinon
    -- asgard_cherche_executant émet une erreur)
    executant := z_asgard.asgard_cherche_executant(
        'MODIFY GESTION SCHEMA', new_producteur := NEW.producteur
    ) ;
    EXECUTE format('SET ROLE %I', executant) ;

    -- on signale la fin du traitement, ce qui
    -- va notamment permettre l'exécution de
    -- asgard_visibilite_admin_after
    UPDATE z_asgard.gestion_schema_etr
        SET ctrl = ARRAY['END', 'x7-A;#rzo']
        WHERE nom_schema = NEW.nom_schema
            AND (ctrl[1] IS NULL OR NOT ctrl[1] = 'EXIT') ;

    EXECUTE format('SET ROLE %I', utilisateur) ;
    
	RETURN NULL ;

EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                            e_hint = PG_EXCEPTION_HINT,
                            e_detl = PG_EXCEPTION_DETAIL,
                            e_errcode = RETURNED_SQLSTATE,
                            e_schema = SCHEMA_NAME ;
    
    RAISE EXCEPTION '%', z_asgard.asgard_prefixe_erreur(e_mssg, 'TA')
        USING DETAIL = e_detl,
            HINT = e_hint,
            SCHEMA = coalesce(nullif(e_schema, ''), NEW.nom_schema, '???'),
            ERRCODE = e_errcode ;
               
END
$_$ ;

ALTER FUNCTION z_asgard_admin.asgard_on_modify_gestion_schema_after()
    OWNER TO g_admin ;

COMMENT ON FUNCTION z_asgard_admin.asgard_on_modify_gestion_schema_after() IS 'ASGARD. Fonction exécutée par le déclencheur asgard_on_modify_gestion_schema_after sur z_asgard_admin.gestion_schema, qui répercute physiquement les modifications de la table de gestion.' ;


-- Trigger: asgard_on_modify_gestion_schema_after

CREATE TRIGGER asgard_on_modify_gestion_schema_after
    AFTER INSERT OR UPDATE
    ON z_asgard_admin.gestion_schema
    FOR EACH ROW
    EXECUTE PROCEDURE z_asgard_admin.asgard_on_modify_gestion_schema_after() ;

COMMENT ON TRIGGER asgard_on_modify_gestion_schema_after ON z_asgard_admin.gestion_schema IS 'ASGARD. Déclencheur qui répercute physiquement les modifications de la table de gestion.' ;


------ 5.3 - TRIGGER DE GESTION DES PERMISSIONS DE G_ADMIN ------

-- Function: z_asgard_admin.asgard_visibilite_admin_after()

CREATE OR REPLACE FUNCTION z_asgard_admin.asgard_visibilite_admin_after()
    RETURNS trigger
    LANGUAGE plpgsql
    SECURITY DEFINER
    AS $_$
/* Fonction exécutée par le déclencheur asgard_visibilite_admin_after sur
z_asgard_admin.gestion_schema, qui assure que g_admin soit toujours membre
des rôles producteurs des schémas référencés, hors super-utilisateurs.

    Cf. description de la fonction z_asgard.asgard_grant_producteur_to_g_admin
    sur laquelle elle s'appuie pour plus de détails.

    Notes
    -----
    Contrairement aux autres objets d'Asgard, cette fonction appartient au
    rôle super-utilisateur qui a activé l'extension et s'exécute avec les
    droits de ce rôle.

    Ne pas renommer le déclencheur asgard_visibilite_admin_after à la légère.
    Il est essentiel que cette fonction soit lancée alors que la table
    de gestion est déjà à jour, soit après l'exécution de la fonction
    asgard_on_modify_gestion_schema_after(). Pour mémoire, l'ordre
    d'activation des déclencheurs est déterminé par un tri alphabétique
    de leurs noms.

    Raises
    ------
    trigger_protocol_violated
        TVA1. Lorsque la fonction est utilisée dans un contexte autre que
        celui prévu par Asgard.

    Version notes
    -------------
    v1.5.0
        (M) La fonction (qui avait et conserve la propriété SECURITY DEFINER)
            appartient désormais au super-utilisateur qui a activé l'extension 
            et plus à g_admin. Avec PostgreSQL 16+, seul un super-utilisateur est 
            en effet assuré de pouvoir donner à g_admin des permissions sur 
            n'importe quel rôle producteur non super-utilisateur. L'attribut
            CREATEROLE de g_admin ne donne plus cette prérogative.
        (M) L'attribution effective des permissions est déléguée à 
            asgard_grant_producteur_to_g_admin, ainsi que certains contrôles
            afférents. Par l'intermédiaire de asgard_grant_producteur_to_g_admin,
            des paramètres de configuration permettent désormais :
            - D'autoriser les rôles de connexion non super-utilisateurs à être 
              producteurs de schémas (g_admin en est rendu membre).
            - D'autoriser les rôles membres de g_admin, directement ou non, 
              à être producteurs de schémas (g_admin n'en est pas rendu membre).
            - D'inhiber complètement l'attribution de permissions à g_admin sur
              les producteurs.
            Par défaut, g_admin reçoit désormais l'option ADMIN sur les 
            producteurs. Un autre paramètre de configuration permet de le rendre 
            membre des rôles sans cette option.
            asgard_grant_producteur_to_g_admin, et donc la présente fonction, 
            veillent désormais à ce que les rôles de connexion ne deviennent pas 
            producteurs de schémas. Ce contrôle relevait auparavant de
            asgard_on_modify_gestion_schema_after.
        (m) Amélioration de la gestion des messages d'erreur.

*/
DECLARE
    e_mssg text ;
    e_hint text ;
    e_detl text ;
    e_errcode text ;
    e_schema text ;
BEGIN
  
    ------ CONTRÔLES PREALABLES ------
    -- comme asgard_visibilite_admin_after() est une fonction SECURITY DEFINER,
    -- on s'assure qu'elle est bien appelée dans le seul contexte autorisé,
    -- à savoir par un trigger asgard_visibilite_admin_after sur une table
    -- z_asgard_admin.gestion_schema.
    IF NOT TG_TABLE_NAME = 'gestion_schema' OR NOT TG_TABLE_SCHEMA = 'z_asgard_admin'
        OR NOT TG_NAME = 'asgard_visibilite_admin_after'
    THEN
        RAISE EXCEPTION 'TVA1. Opération interdite. La fonction asgard_visibilite_admin_after() ne peut être appelée que par le déclencheur asgard_visibilite_admin_after défini sur la table z_asgard_admin.gestion_schema.'
            USING ERRCODE = 'trigger_protocol_violated' ;
    END IF ;

    ------ REQUETES AUTO A IGNORER ------
    -- ce trigger ne doit être déclenché qu'une fois, après la
    -- fin de l'exécution de asgard_modify_gestion_schema_after,
    -- soit quand ctrl indique END
    IF NEW.ctrl[1] IS NULL OR NOT NEW.ctrl[1] = 'END'
    THEN
        -- aucune action
        RETURN NULL ;
    END IF ;

    ------ SCHEMAS INACTIFS ------
    -- on écarte les schémas non actifs
    IF NOT NEW.creation
    THEN
        RETURN NULL ;
    END IF ;

    -- pas de contrôle sur le fait que le producteur a changé, car il n'est
    -- pas plus mal de confirmer les permissions de g_admin, au cas où elles
    -- auraient été supprimées entre temps, ce qui ne sera jamais une bonne
    -- chose

    PERFORM z_asgard.asgard_grant_producteur_to_g_admin(
        NEW.producteur, permissif := False 
    ) ;

    RETURN NULL ;
    
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                            e_hint = PG_EXCEPTION_HINT,
                            e_detl = PG_EXCEPTION_DETAIL,
                            e_errcode = RETURNED_SQLSTATE,
                            e_schema = SCHEMA_NAME ;
    
    RAISE EXCEPTION '%', z_asgard.asgard_prefixe_erreur(e_mssg, 'TVA')
        USING DETAIL = e_detl,
            HINT = e_hint,
            SCHEMA = coalesce(nullif(e_schema, ''), NEW.nom_schema, '???'),
            ERRCODE = e_errcode ;
               
END
$_$ ;
    
COMMENT ON FUNCTION z_asgard_admin.asgard_visibilite_admin_after() IS 'ASGARD. Fonction exécutée par le déclencheur asgard_visibilite_admin_after sur z_asgard_admin.gestion_schema, qui assure que g_admin soit toujours membre des rôles producteurs des schémas référencés, hors super-utilisateurs.' ;


-- Trigger: asgard_visibilite_admin_after

CREATE TRIGGER asgard_visibilite_admin_after
    AFTER INSERT OR UPDATE
    ON z_asgard_admin.gestion_schema
    FOR EACH ROW
    EXECUTE PROCEDURE z_asgard_admin.asgard_visibilite_admin_after() ;

COMMENT ON TRIGGER asgard_visibilite_admin_after ON z_asgard_admin.gestion_schema IS 'ASGARD. Déclencheur qui assure que g_admin soit toujours membre des rôles producteurs des schémas référencés, hors super-utilisateurs.' ;


-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

-----------------------------------------------------------
------ 6 - GESTION DES PERMISSIONS SUR LAYER_STYLES ------
-----------------------------------------------------------
/* 6.1 - PETITES FONCTIONS UTILITAIRES
   6.2 - FONCTION D'ADMINISTRATION DES PERMISSIONS SUR LAYER_STYLES */

------ 6.1 - PETITES FONCTIONS UTILITAIRES ------

-- Function: z_asgard.asgard_is_relation_owner(text, text, text)

CREATE OR REPLACE FUNCTION z_asgard.asgard_is_relation_owner(
    nom_schema text,
    nom_relation text,
    nom_role text DEFAULT current_user
    )
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
/* Détermine si un rôle est membre du propriétaire d'une table, vue ou autre relation.

    Tous les arguments sont en écriture naturelle, sans les
    guillemets des identifiants PostgreSQL.

    Parameters
    ----------
    nom_schema : text
        Chaîne de caractères correspondant au nom du schéma dont
        dépend la relation.
    nom_relation : text
        Chaîne de caractères correspondant au nom de la relation.
    nom_role : text, optional
        Nom du rôle dont on veut vérifier les permissions. Si non
        renseigné, la fonction testera l'utilisateur courant.

    Returns
    -------
    boolean
        True si le rôle est membre du propriétaire de la relation.
        False sinon, incluant les cas où le rôle ou la relation n'existe
        pas.

*/
DECLARE
    owner text ;
BEGIN
    
    SELECT pg_roles.rolname INTO owner
        FROM pg_catalog.pg_class
            LEFT JOIN pg_catalog.pg_roles ON pg_roles.oid = relowner
        WHERE quote_ident(nom_schema) = relnamespace::regnamespace::text
            AND nom_relation = relname ;
        
    IF NOT FOUND
    THEN
        RETURN False ;
    END IF ;
    
    RETURN z_asgard.asgard_has_role_usage(owner, nom_role) ;
    
END
$_$;

ALTER FUNCTION z_asgard.asgard_is_relation_owner(text, text, text)
    OWNER TO g_admin_ext ;

COMMENT ON FUNCTION z_asgard.asgard_is_relation_owner(text, text, text) IS 'ASGARD. Détermine si un rôle est membre du propriétaire d''une table, vue ou autre relation.' ;


-- Function: z_asgard.asgard_is_producteur(text, text)

CREATE OR REPLACE FUNCTION z_asgard.asgard_is_producteur(
    schema_cible text,
    nom_role text DEFAULT current_user
    )
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
/* Détermine si le rôle considéré est membre du rôle producteur d'un schéma donné.

    Tous les arguments sont en écriture naturelle, sans les
    guillemets des identifiants PostgreSQL.

    Parameters
    ----------
    nom_schema : text
        Chaîne de caractères correspondant à un nom de schéma.
    nom_role : text, optional
        Nom du rôle dont on veut vérifier les permissions. Si
        non renseigné, la fonction testera l'utilisateur courant.

    Returns
    -------
    boolean
        True si le rôle est membre du rôle producteur du schéma.
        False si le schéma n'existe pas ou si le rôle n'est pas
        membre de son producteur.

*/
DECLARE
    producteur text ;
BEGIN
    
    SELECT gestion_schema_read_only.producteur INTO producteur
        FROM z_asgard.gestion_schema_read_only
        WHERE gestion_schema_read_only.nom_schema = schema_cible ;
        
    IF producteur IS NULL
    THEN
        RETURN False ;
    END IF ;
    
    RETURN z_asgard.asgard_has_role_usage(producteur, nom_role) ;
    
END
$_$ ;

ALTER FUNCTION z_asgard.asgard_is_producteur(text, text)
    OWNER TO g_admin_ext ;

COMMENT ON FUNCTION z_asgard.asgard_is_producteur(text, text) IS 'ASGARD. Détermine si le rôle considéré est membre du rôle producteur d''un schéma donné.' ;


-- Function: z_asgard.asgard_is_editeur(text, text)

CREATE OR REPLACE FUNCTION z_asgard.asgard_is_editeur(
    schema_cible text,
    nom_role text DEFAULT current_user
    )
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
/* Détermine si le rôle considéré est membre du rôle éditeur d'un schéma donné.

    Tous les arguments sont en écriture naturelle, sans les
    guillemets des identifiants PostgreSQL.

    Parameters
    ----------
    nom_schema : text
        Chaîne de caractères correspondant à un nom de schéma.
    nom_role : text, optional
        Nom du rôle dont on veut vérifier les permissions. Si
        non renseigné, la fonction testera l'utilisateur courant.

    Returns
    -------
    boolean
        True si le rôle est membre du rôle éditeur du schéma.
        False si le schéma n'existe pas ou si le rôle n'est pas
        membre de son éditeur.

*/
DECLARE
    editeur text ;
BEGIN
    
    SELECT gestion_schema_read_only.editeur INTO editeur
        FROM z_asgard.gestion_schema_read_only
        WHERE gestion_schema_read_only.nom_schema = schema_cible ;
        
    IF editeur is NULL
    THEN
        RETURN False ;
    END IF ;
    
    RETURN z_asgard.asgard_has_role_usage(editeur, nom_role) ;
    
END
$_$;

ALTER FUNCTION z_asgard.asgard_is_editeur(text, text)
    OWNER TO g_admin_ext ;

COMMENT ON FUNCTION z_asgard.asgard_is_editeur(text, text) IS 'ASGARD. Détermine si le rôle considéré est membre du rôle éditeur d''un schéma donné.' ;


-- Function: z_asgard.asgard_is_lecteur(text, text)

CREATE OR REPLACE FUNCTION z_asgard.asgard_is_lecteur(
    schema_cible text,
    nom_role text DEFAULT current_user
    )
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
/* Détermine si le rôle considéré est membre du rôle lecteur d'un schéma donné.

    Tous les arguments sont en écriture naturelle, sans les
    guillemets des identifiants PostgreSQL.

    Parameters
    ----------
    nom_schema : text
        Chaîne de caractères correspondant à un nom de schéma.
    nom_role : text, optional
        Nom du rôle dont on veut vérifier les permissions. Si
        non renseigné, la fonction testera l'utilisateur courant.

    Returns
    -------
    boolean
        True si le rôle est membre du rôle lecteur du schéma.
        False si le schéma n'existe pas ou si le rôle n'est pas
        membre de son lecteur.

*/
DECLARE
    lecteur text ;
BEGIN
    
    SELECT gestion_schema_read_only.lecteur INTO lecteur
        FROM z_asgard.gestion_schema_read_only
        WHERE gestion_schema_read_only.nom_schema = schema_cible ;
        
    IF lecteur IS NULL
    THEN
        RETURN False ;
    END IF ;
    
    RETURN z_asgard.asgard_has_role_usage(lecteur, nom_role) ;
    
END
$_$;

ALTER FUNCTION z_asgard.asgard_is_lecteur(text, text)
    OWNER TO g_admin_ext ;

COMMENT ON FUNCTION z_asgard.asgard_is_lecteur(text, text) IS 'ASGARD. Détermine si le rôle considéré est membre du rôle lecteur d''un schéma donné.' ;


------ 6.2 - FONCTION D'ADMINISTRATION DES PERMISSIONS SUR LAYER_STYLES ------

-- Function: z_asgard_admin.asgard_layer_styles(int)

CREATE OR REPLACE FUNCTION z_asgard_admin.asgard_layer_styles(variante int)
    RETURNS text
    LANGUAGE plpgsql
    AS $_$
/* Confère à g_consult un accès en lecture à la table layer_styles du schéma public 
   (table créée par QGIS pour stocker les styles de couches), ainsi que des
   droits d'écriture selon la stratégie spécifiée par le paramètre "variante".

    Cette fonction échoue si la table layer_styles n'existe pas.
    
    Il est possible de relancer la fonction à volonté pour modifier 
    la stratégie à mettre en oeuvre.
    
    Hormis pour la variante 0, la fonction a pour effet d'activer
    la sécurisation niveau ligne sur la table, ce qui pourra
    rendre inopérants des accès précédemment définis.

    Parameters
    ----------
    variante : int
        Variante est un entier spécifiant les droits à donner en écriture.
        - 0 : autorise g_admin à modifier layer_styles. À noter que cette option
          n'a d'intérêt que si g_admin n'est pas propriétaire de la table 
          layer_styles ;
        - 1 : idem 0 + autorise le producteur d'un schéma à modifier les styles
          associés aux tables qu'il contient ;
        - 2 : idem 1 + autorise l'éditeur d'un schéma à enregistrer de nouveaux
          styles (INSERT) pour les tables du schéma et à modifier (UPDATE et DELETE)
          les styles tels que le champ "owner" de layer_styles contient un rôle dont
          l'utilisateur est membre (généralement son propre rôle de connexion), tout
          cela sous réserve que le style ne soit pas identifié comme style par défaut ;
        - 3 : idem 2 sans la condition sur les styles par défaut ;
        - 4 : idem 3 sans la condition d'appartenance au rôle "owner" du style ;
        - 5 : idem 2, mais les mêmes autorisations sont également données au
          lecteur du schéma ;
        - 99 : supprime tous les droits accordés par les autres stratégies (y
          compris l'accès en lecture de g_consult).
    
    Returns
    -------
    text
        '__ FIN ATTRIBUTION PERMISSIONS.' (ou '__ FIN SUPPRESSION PERMISSIONS.'
        pour la variante 99) si l'opération s'est déroulée comme prévu.

    Raises
    ------
    undefined_table
        ALS1. Si public.layer_style n'existe pas.

    Version notes
    -------------
    v1.5.0
        (M) Recours à asgard_cherche_executant pour trouver 
            des rôles habilités à lancer les commandes.
            Le contrôle des permissions de l'utilisateur est 
            dorénavant entièrement délégué à cette fonction.
        (m) Amélioration de la gestion des messages d'erreur.
        (d) Enrichissement du descriptif.
        
*/
DECLARE
    executant text ;
    utilisateur text := current_user ;
    layer_style_owner text ;
    e_mssg text ;
    e_detl text ;
    e_hint text ;
    e_schema text ;
    e_errcode text ;
BEGIN

    -- récupération du propriétaire de layer_style
    SELECT pg_roles.rolname
        INTO layer_style_owner
        FROM pg_catalog.pg_class
            INNER JOIN pg_catalog.pg_roles 
                ON pg_roles.oid = pg_class.relowner
        WHERE pg_class.relnamespace = 'public'::regnamespace
            AND pg_class.relname = 'layer_styles' ;

    IF NOT FOUND
    THEN
        RAISE EXCEPTION 'ALS1. La table layer_styles n''existe pas.'
            USING ERRCODE = 'undefined_table' ;
    END IF ;

    -- choix d'un rôle habilité à exécuter les commandes (sinon
    -- asgard_cherche_executant émet une erreur)
    executant := z_asgard.asgard_cherche_executant(
        'POLICIES',
        new_producteur := layer_style_owner
    ) ;
    EXECUTE format('SET ROLE %I', executant) ;

    ------ NETTOYAGE ------
    
    -- suppression des droits
    IF NOT z_asgard.asgard_is_relation_owner('public', 'layer_styles', 'g_consult')
    THEN
        REVOKE SELECT, INSERT, UPDATE, DELETE ON layer_styles FROM g_consult ;
        REVOKE SELECT, USAGE ON SEQUENCE layer_styles_id_seq FROM g_consult ;
    END IF ;
    IF NOT z_asgard.asgard_is_relation_owner('public', 'layer_styles', 'g_admin')
    THEN
        REVOKE SELECT, INSERT, UPDATE, DELETE ON layer_styles FROM g_admin ;
        REVOKE SELECT, USAGE ON SEQUENCE layer_styles_id_seq FROM g_admin ;
    END IF ;
    
    -- suppression des politiques de sécurité
    DROP POLICY IF EXISTS asgard_layer_styles_public_select ON layer_styles ;
    DROP POLICY IF EXISTS asgard_layer_styles_producteur_insert ON layer_styles ;
    DROP POLICY IF EXISTS asgard_layer_styles_producteur_update ON layer_styles ;
    DROP POLICY IF EXISTS asgard_layer_styles_producteur_delete ON layer_styles ;
    DROP POLICY IF EXISTS asgard_layer_styles_editeur_insert ON layer_styles ;
    DROP POLICY IF EXISTS asgard_layer_styles_editeur_update ON layer_styles ;
    DROP POLICY IF EXISTS asgard_layer_styles_editeur_delete ON layer_styles ;
    DROP POLICY IF EXISTS asgard_layer_styles_lecteur_insert ON layer_styles ;
    DROP POLICY IF EXISTS asgard_layer_styles_lecteur_update ON layer_styles ;
    DROP POLICY IF EXISTS asgard_layer_styles_lecteur_delete ON layer_styles ;
    
    -- désactivation de la sécurisation niveau ligne
    ALTER TABLE layer_styles DISABLE ROW LEVEL SECURITY ;
    
    IF variante = 99
    THEN
        EXECUTE format('SET ROLE %I', utilisateur) ;

        RETURN '__ FIN SUPPRESSION PERMISSIONS.' ;
    END IF ;
    
    ------ NOUVELLE STRATEGIE -------
    
    IF variante = 0
    THEN
        -- droits de lecture pour g_consult
        GRANT SELECT ON layer_styles TO g_consult ;
        GRANT SELECT ON SEQUENCE layer_styles_id_seq TO g_consult ;
        
        -- droits d'édition pour g_admin
        GRANT SELECT, INSERT, UPDATE, DELETE ON layer_styles TO g_admin ;
        GRANT SELECT, USAGE ON SEQUENCE layer_styles_id_seq TO g_admin ;
        
        EXECUTE format('SET ROLE %I', utilisateur) ;

        RETURN '__ FIN ATTRIBUTION PERMISSIONS.' ;
    END IF ;
    
    -- activation de la sécurisation niveau ligne
    ALTER TABLE layer_styles ENABLE ROW LEVEL SECURITY ;
    
    -- droits d'édition pour g_admin
    GRANT SELECT, INSERT, UPDATE, DELETE ON layer_styles TO g_admin ;
    GRANT SELECT, USAGE ON SEQUENCE layer_styles_id_seq TO g_admin ;
    -- NB : g_admin a l'attribut BYPASSRLS, donc pourra quoi qu'il
    -- arrive accéder à toutes les lignes de la table.
    
    -- droits étendus pour g_consult
    GRANT SELECT, INSERT, UPDATE, DELETE ON layer_styles TO g_consult ;
    GRANT SELECT, USAGE ON SEQUENCE layer_styles_id_seq TO g_consult ;
    
    -- définition des politiques de sécurité :
    -- - accès en lecture pour tous
    CREATE POLICY asgard_layer_styles_public_select ON layer_styles
        FOR SELECT USING (True) ;

    -- - accès en écriture pour les membres du rôle producteur
    CREATE POLICY asgard_layer_styles_producteur_insert ON layer_styles
        FOR INSERT
        WITH CHECK (z_asgard.asgard_is_producteur(f_table_schema)) ;
    CREATE POLICY asgard_layer_styles_producteur_update ON layer_styles
        FOR UPDATE
        USING (z_asgard.asgard_is_producteur(f_table_schema))
        WITH CHECK (z_asgard.asgard_is_producteur(f_table_schema)) ;
    CREATE POLICY asgard_layer_styles_producteur_delete ON layer_styles
        FOR DELETE
        USING (z_asgard.asgard_is_producteur(f_table_schema)) ;     
    IF variante = 1
    THEN
        EXECUTE format('SET ROLE %I', utilisateur) ;

        RETURN '__ FIN ATTRIBUTION PERMISSIONS.' ;
    END IF ;
    
    -- - accès en écriture pour les membres du rôle éditeur
    IF variante IN (2, 5)
    THEN
        CREATE POLICY asgard_layer_styles_editeur_insert ON layer_styles
            FOR INSERT
            WITH CHECK (z_asgard.asgard_is_editeur(f_table_schema) AND z_asgard.asgard_has_role_usage(owner) AND NOT useasdefault) ;
        CREATE POLICY asgard_layer_styles_editeur_update ON layer_styles
            FOR UPDATE
            USING (z_asgard.asgard_is_editeur(f_table_schema) AND z_asgard.asgard_has_role_usage(owner) AND NOT useasdefault)
            WITH CHECK (z_asgard.asgard_is_editeur(f_table_schema) AND z_asgard.asgard_has_role_usage(owner) AND NOT useasdefault) ;
        CREATE POLICY asgard_layer_styles_editeur_delete ON layer_styles
            FOR DELETE
            USING (z_asgard.asgard_is_editeur(f_table_schema) AND z_asgard.asgard_has_role_usage(owner) AND NOT useasdefault) ;
    ELSIF variante = 3
    THEN
        CREATE POLICY asgard_layer_styles_editeur_insert ON layer_styles
            FOR INSERT
            WITH CHECK (z_asgard.asgard_is_editeur(f_table_schema) AND z_asgard.asgard_has_role_usage(owner)) ;
        CREATE POLICY asgard_layer_styles_editeur_update ON layer_styles
            FOR UPDATE
            USING (z_asgard.asgard_is_editeur(f_table_schema) AND z_asgard.asgard_has_role_usage(owner))
            WITH CHECK (z_asgard.asgard_is_editeur(f_table_schema) AND z_asgard.asgard_has_role_usage(owner)) ;
        CREATE POLICY asgard_layer_styles_editeur_delete ON layer_styles
            FOR DELETE
            USING (z_asgard.asgard_is_editeur(f_table_schema) AND z_asgard.asgard_has_role_usage(owner)) ;
    ELSIF variante = 4
    THEN
        CREATE POLICY asgard_layer_styles_editeur_insert ON layer_styles
            FOR INSERT
            WITH CHECK (z_asgard.asgard_is_editeur(f_table_schema)) ;
        CREATE POLICY asgard_layer_styles_editeur_update ON layer_styles
            FOR UPDATE
            USING (z_asgard.asgard_is_editeur(f_table_schema))
            WITH CHECK (z_asgard.asgard_is_editeur(f_table_schema)) ;
        CREATE POLICY asgard_layer_styles_editeur_delete ON layer_styles
            FOR DELETE
            USING (z_asgard.asgard_is_editeur(f_table_schema)) ; 
    END IF ;
    
    IF variante < 5
    THEN
        EXECUTE format('SET ROLE %I', utilisateur) ;

        RETURN '__ FIN ATTRIBUTION PERMISSIONS.' ;
    END IF ;
    
    -- - accès en écriture pour les membres du rôle lecteur
    CREATE POLICY asgard_layer_styles_lecteur_insert ON layer_styles
        FOR INSERT
        WITH CHECK (z_asgard.asgard_is_lecteur(f_table_schema) AND z_asgard.asgard_has_role_usage(owner) AND NOT useasdefault) ;
    CREATE POLICY asgard_layer_styles_lecteur_update ON layer_styles
        FOR UPDATE
        USING (z_asgard.asgard_is_lecteur(f_table_schema) AND z_asgard.asgard_has_role_usage(owner) AND NOT useasdefault)
        WITH CHECK (z_asgard.asgard_is_lecteur(f_table_schema) AND z_asgard.asgard_has_role_usage(owner) AND NOT useasdefault) ;
    CREATE POLICY asgard_layer_styles_lecteur_delete ON layer_styles
        FOR DELETE
        USING (z_asgard.asgard_is_lecteur(f_table_schema) AND z_asgard.asgard_has_role_usage(owner) AND NOT useasdefault) ;

    EXECUTE format('SET ROLE %I', utilisateur) ;

    RETURN '__ FIN ATTRIBUTION PERMISSIONS.' ;

EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                            e_hint = PG_EXCEPTION_HINT,
                            e_detl = PG_EXCEPTION_DETAIL,
                            e_errcode = RETURNED_SQLSTATE,
                            e_schema = SCHEMA_NAME ;
         
    RAISE EXCEPTION '%', z_asgard.asgard_prefixe_erreur(e_mssg, 'ALS')
        USING DETAIL = e_detl,
            HINT = e_hint,
            SCHEMA = e_schema,
            ERRCODE = e_errcode ;

END
$_$ ;

ALTER FUNCTION z_asgard_admin.asgard_layer_styles(int)
    OWNER TO g_admin ;

COMMENT ON FUNCTION z_asgard_admin.asgard_layer_styles(int) IS 'ASGARD. Fonction qui définit des permissions sur la table layer_styles de QGIS.' ;

-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
