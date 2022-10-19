\echo Use "ALTER EXTENSION plume_pg UPDATE TO '1.4.0'" to load this file. \quit
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
--
-- ASGARD - Système de gestion des droits pour PostgreSQL, version 1.4.0
-- > Script de mise à jour depuis la version 1.3.2.
--
-- Copyright République Française, 2020-2022.
-- Secrétariat général du Ministère de la Transition écologique et
-- de la Cohésion des territoires, du Ministère de la Transition
-- énergétique et du Secrétariat d'Etat à la Mer.
-- Direction du numérique.
--
-- contributrice pour cette version : Leslie Lemaire (SNUM/UNI/DRC).
-- 
-- mél : drc.uni.snum.sg@developpement-durable.gouv.fr
--
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
--
-- Note de version :
-- https://snum.scenari-community.org/Asgard/Documentation/#SEC_1-4-0
-- 
-- Documentation :
-- https://snum.scenari-community.org/Asgard/Documentation/
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
-- Elle n'est pas compatible avec les versions 9.4 ou antérieures de
-- PostgreSQL.
--
-- schémas contenant les objets : z_asgard et z_asgard_admin.
--
-- objets créés par le script :
-- - Function: z_asgard_admin.asgard_visibilite_admin_after()
-- - Trigger: asgard_visibilite_admin_after
--
-- objets modifiés par le script (parfois seulement leur descriptif) :
-- - Schema: z_asgard
-- - Table: z_asgard_admin.gestion_schema
-- - View: z_asgard.gestion_schema_usr
-- - View: z_asgard.gestion_schema_etr
-- - View: z_asgard.asgardmenu_metadata
-- - View: z_asgard.asgardmanager_metadata
-- - View: z_asgard.gestion_schema_read_only
-- - Function: z_asgard_admin.asgard_on_alter_schema()
-- - Event Trigger: asgard_on_alter_schema
-- - Function: z_asgard_admin.asgard_on_create_schema()
-- - Event Trigger: asgard_on_create_schema
-- - Function: z_asgard_admin.asgard_on_drop_schema()
-- - Event Trigger: asgard_on_drop_schema
-- - Function: z_asgard_admin.asgard_on_create_objet()
-- - Event Trigger: asgard_on_create_objet
-- - Function: z_asgard_admin.asgard_on_alter_objet()
-- - Event Trigger: asgard_on_alter_objet
-- - Function: z_asgard.asgard_admin_proprietaire(text, text, boolean)
-- - Function: z_asgard_admin.asgard_initialisation_gestion_schema(text[], boolean)
-- - Function: z_asgard.asgard_initialise_schema(text, boolean, boolean)
-- - Function: z_asgard.asgard_initialise_obj(text, text, text)
-- - Function: z_asgard.asgard_deplace_obj(text, text, text, text, int)
-- - Function: z_asgard_admin.asgard_all_login_grant_role(text, boolean)
-- - Function: z_asgard_admin.asgard_diagnostic(text[])
-- - Function: z_asgard_admin.asgard_on_modify_gestion_schema_before()
-- - Trigger: asgard_on_modify_gestion_schema_before
-- - Function: z_asgard_admin.asgard_on_modify_gestion_schema_after()
-- - Trigger: asgard_on_modify_gestion_schema_after
-- - Function: z_asgard.asgard_has_role_usage(text, text)
-- - Function: z_asgard.asgard_is_relation_owner(text, text)
-- - Function: z_asgard.asgard_is_producteur(text, text)
-- - Function: z_asgard.asgard_is_editeur(text, text)
-- - Function: z_asgard.asgard_is_lecteur(text, text)
--
-- objets supprimés par le script :
-- - Function: z_asgard.asgard_role_trans_acl(regrole)
--
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


/* 2 - PREPARATION DES OBJETS
   3 - CREATION DES EVENT TRIGGERS
   4 - FONCTIONS UTILITAIRES
   6 - GESTION DES PERMISSIONS SUR LAYER_STYLES */

-- MOT DE PASSE DE CONTRÔLE : 'x7-A;#rzo'


-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

----------------------------------------
------ 2 - PREPARATION DES OBJETS ------
----------------------------------------

/* 2.1 - CREATION DES SCHEMAS
   2.2 - TABLE GESTION_SCHEMA
   2.4 - VUES D'ALIMENTATION DE GESTION_SCHEMA
   2.6 - VUE POUR ASGARDMENU
   2.7 - VUE POUR ASGARDMANAGER
   2.8 - VERSION LECTURE SEULE DE GESTION_SCHEMA_USR */

-- Le cas échéant, le lecteur et l'éditeur de z_asgard sont révoqués :
UPDATE z_asgard_admin.gestion_schema
    SET lecteur = NULL,
        editeur = NULL
    WHERE nom_schema = 'z_asgard' ;

------ 2.1 - CREATION DES SCHEMAS ------

-- Schema: z_asgard

REVOKE USAGE ON SCHEMA z_asgard FROM g_consult ;
GRANT USAGE ON SCHEMA z_asgard TO public ;

------ 2.2 - TABLE GESTION_SCHEMA ------

-- Table: z_asgard_admin.gestion_schema

ALTER TABLE z_asgard_admin.gestion_schema
    DROP CONSTRAINT gestion_schema_ctrl_check ;

ALTER TABLE z_asgard_admin.gestion_schema
    ADD CONSTRAINT gestion_schema_ctrl_check
        CHECK (ctrl IS NULL OR array_length(ctrl, 1) >= 2
            AND ctrl[1] IN ('CREATE', 'RENAME', 'OWNER', 'DROP', 'SELF', 'MANUEL', 'EXIT', 'END')) ;

------ 2.4 - VUES D'ALIMENTATION DE GESTION_SCHEMA ------

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
                ELSE has_database_privilege(current_database()::text, 'CREATE'::text) OR CURRENT_USER = gestion_schema.producteur::name
            END
) ;

REVOKE SELECT ON TABLE z_asgard.gestion_schema_usr FROM g_consult ;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE z_asgard.gestion_schema_usr TO public ;

-- View: z_asgard.gestion_schema_etr

REVOKE SELECT ON TABLE z_asgard.gestion_schema_etr FROM g_consult ;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE z_asgard.gestion_schema_etr TO public ;

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
                ELSE has_database_privilege(current_database()::text, 'CREATE'::text) OR CURRENT_USER = gestion_schema.producteur::name
            END
) ;

------ View: z_asgard.asgardmenu_metadata ------

REVOKE SELECT ON TABLE z_asgard.asgardmenu_metadata FROM g_consult ;
GRANT SELECT ON TABLE z_asgard.asgardmenu_metadata TO public ;

------ View: z_asgard.asgardmanager_metadata ------

REVOKE SELECT ON TABLE z_asgard.asgardmanager_metadata FROM g_consult ;
GRANT SELECT ON TABLE z_asgard.asgardmanager_metadata TO public ;

------ View: z_asgard.gestion_schema_read_only ------

REVOKE SELECT ON TABLE z_asgard.gestion_schema_read_only FROM g_consult ;
GRANT SELECT ON TABLE z_asgard.gestion_schema_read_only TO public ;


-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

---------------------------------------------
------ 3 - CREATION DES EVENT TRIGGERS ------
---------------------------------------------

/* 3.1 - EVENT TRIGGER SUR ALTER SCHEMA
   3.2 - EVENT TRIGGER SUR CREATE SCHEMA
   3.3 - EVENT TRIGGER SUR DROP SCHEMA
   3.4 - EVENT TRIGGER SUR CREATE OBJET
   3.5 - EVENT TRIGGER SUR ALTER OBJET */


------ 3.1 - EVENT TRIGGER SUR ALTER SCHEMA ------

-- Function: z_asgard_admin.asgard_on_alter_schema()

CREATE OR REPLACE FUNCTION z_asgard_admin.asgard_on_alter_schema()
    RETURNS event_trigger
    LANGUAGE plpgsql
    AS $BODY$
/* Fonction exécutée par le déclencheur sur évènement asgard_on_alter_schema,
qui répercute sur la table de gestion d'Asgard les changements de noms et
propriétaires réalisés par des commandes ALTER SCHEMA directes.

    Elle n'écrit pas directement dans la table z_asgard_admin.gestion_schema,
    mais dans la vue modifiable z_asgard.gestion_schema_etr.

*/
DECLARE
    obj record ;
    objname text ;
    e_mssg text ;
    e_hint text ;
    e_detl text ;
BEGIN
    ------ CONTROLES DES PRIVILEGES ------
    IF NOT has_schema_privilege('z_asgard', 'USAGE')
    THEN
        RAISE EXCEPTION 'EAS1. Schéma z_asgard inaccessible.' ;
    END IF ;
    
    IF NOT has_table_privilege('z_asgard.gestion_schema_etr', 'UPDATE')
        OR NOT has_table_privilege('z_asgard.gestion_schema_etr', 'SELECT')
    THEN
        RAISE EXCEPTION 'EAS2. Permissions insuffisantes pour la vue z_asgard.gestion_schema_etr.' ;
    END IF ;


	FOR obj IN SELECT * FROM pg_event_trigger_ddl_commands()
        WHERE object_type = 'schema'
    LOOP
    
        ------ RENAME ------
        UPDATE z_asgard.gestion_schema_etr
            SET nom_schema = nspname,
                ctrl = ARRAY['RENAME', 'x7-A;#rzo']
            FROM pg_catalog.pg_namespace
            WHERE oid_schema = obj.objid
                AND obj.objid = pg_namespace.oid
                AND NOT nom_schema = nspname
            RETURNING nspname INTO objname ;
        IF FOUND
        THEN
            RAISE NOTICE '... Le nom du schéma % a été mis à jour dans la table de gestion.',  objname ;
        END IF ;

        ------ OWNER TO ------
        UPDATE z_asgard.gestion_schema_etr
            SET producteur = rolname,
                oid_producteur = nspowner,
                ctrl = ARRAY['OWNER', 'x7-A;#rzo']
            FROM pg_catalog.pg_namespace
                LEFT JOIN pg_catalog.pg_roles ON pg_roles.oid = nspowner
            WHERE oid_schema = obj.objid
                AND obj.objid = pg_namespace.oid
                AND NOT oid_producteur = nspowner
            RETURNING nspname INTO objname ;
        IF FOUND
        THEN
            RAISE NOTICE '... Le producteur du schéma % a été mis à jour dans la table de gestion.',  objname ;
        END IF ;

    END LOOP ;
    
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                            e_hint = PG_EXCEPTION_HINT,
                            e_detl = PG_EXCEPTION_DETAIL ;
    RAISE EXCEPTION 'EAS0 > %', e_mssg
        USING DETAIL = e_detl,
            HINT = e_hint ;

END
$BODY$ ;

ALTER FUNCTION z_asgard_admin.asgard_on_alter_schema()
    OWNER TO g_admin ;
    
COMMENT ON FUNCTION z_asgard_admin.asgard_on_alter_schema() IS 'ASGARD. Fonction exécutée par le déclencheur sur évènement asgard_on_alter_schema, qui répercute sur la table de gestion d''Asgard les changements de noms et propriétaires réalisés par des commandes ALTER SCHEMA directes.' ;


-- Event Trigger: asgard_on_alter_schema

COMMENT ON EVENT TRIGGER asgard_on_alter_schema IS 'ASGARD. Déclencheur sur évènement qui répercute sur la table de gestion d''Asgard les changements de noms et propriétaires réalisés par des commandes ALTER SCHEMA directes.' ;


------ 3.2 - EVENT TRIGGER SUR CREATE SCHEMA ------

-- Function: z_asgard_admin.asgard_on_create_schema()

CREATE OR REPLACE FUNCTION z_asgard_admin.asgard_on_create_schema() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $BODY$
/* Fonction exécutée par le déclencheur sur évènement asgard_on_create_schema,
qui répercute sur la table de gestion d'Asgard les créations de schémas réalisées
par des commandes CREATE SCHEMA directes.

    Elle n'écrit pas directement dans la table z_asgard_admin.gestion_schema,
    mais dans la vue modifiable z_asgard.gestion_schema_etr.

*/
DECLARE
    obj record ;
    objname text ;
    e_mssg text ;
    e_hint text ;
    e_detl text ;
BEGIN
    ------ CONTROLES DES PRIVILEGES ------
    IF NOT has_schema_privilege('z_asgard', 'USAGE')
    THEN
        RAISE EXCEPTION 'ECS1. Schéma z_asgard inaccessible.' ;
    END IF ;
    
    IF NOT has_table_privilege('z_asgard.gestion_schema_etr', 'UPDATE')
        OR NOT has_table_privilege('z_asgard.gestion_schema_etr', 'INSERT')
        OR NOT has_table_privilege('z_asgard.gestion_schema_etr', 'SELECT')
    THEN
        RAISE EXCEPTION 'ECS2. Permissions insuffisantes pour la vue z_asgard.gestion_schema_etr.' ;
    END IF ;


	FOR obj IN SELECT * FROM pg_event_trigger_ddl_commands()
        WHERE object_type = 'schema'
    LOOP
    
        ------ SCHEMA PRE-ENREGISTRE DANS GESTION_SCHEMA ------
        UPDATE z_asgard.gestion_schema_etr
            SET oid_schema = obj.objid,
                producteur = rolname,
                oid_producteur = nspowner,
                creation = True,
                ctrl = ARRAY['CREATE', 'x7-A;#rzo']
            FROM pg_catalog.pg_namespace
                LEFT JOIN pg_catalog.pg_roles ON pg_roles.oid = nspowner
            WHERE quote_ident(nom_schema) = obj.object_identity
                AND obj.objid = pg_namespace.oid
                AND NOT creation
            RETURNING nspname INTO objname ;
            -- creation vaut true si et seulement si la création a été initiée via la table
            -- de gestion dans ce cas, il n'est pas nécessaire de réintervenir dessus
        IF FOUND
        THEN
            RAISE NOTICE '... Le schéma % apparaît désormais comme "créé" dans la table de gestion.', objname ;

        ------ SCHEMA NON REPERTORIE DANS GESTION_SCHEMA ------
        ELSIF NOT obj.object_identity IN (SELECT quote_ident(nom_schema) FROM z_asgard.gestion_schema_etr)
        THEN
            INSERT INTO z_asgard.gestion_schema_etr (oid_schema, nom_schema, producteur, oid_producteur, creation, ctrl)(
                SELECT
                    obj.objid,
                    nspname,
                    rolname,
                    nspowner,
                    True,
                    ARRAY['CREATE', 'x7-A;#rzo']
                    FROM pg_catalog.pg_namespace
                        LEFT JOIN pg_catalog.pg_roles ON pg_roles.oid = nspowner
                    WHERE obj.objid = pg_namespace.oid
                )
                RETURNING nom_schema INTO objname ;
            RAISE NOTICE '... Le schéma % a été enregistré dans la table de gestion.', objname ;
        END IF ;
        
	END LOOP ;
    
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                            e_hint = PG_EXCEPTION_HINT,
                            e_detl = PG_EXCEPTION_DETAIL ;
    RAISE EXCEPTION 'ECS0 > %', e_mssg
        USING DETAIL = e_detl,
            HINT = e_hint ;
               
END
$BODY$ ;

ALTER FUNCTION z_asgard_admin.asgard_on_create_schema()
    OWNER TO g_admin ;
    
COMMENT ON FUNCTION z_asgard_admin.asgard_on_create_schema() IS 'ASGARD. Fonction exécutée par le déclencheur sur évènement asgard_on_create_schema, qui répercute sur la table de gestion d''Asgard les créations de schémas réalisées par des commandes CREATE SCHEMA directes.' ;


-- Event Trigger: asgard_on_create_schema
    
COMMENT ON EVENT TRIGGER asgard_on_create_schema IS 'ASGARD. Déclencheur sur évènement qui répercute sur la table de gestion d''Asgard les créations de schémas réalisées par des commandes CREATE SCHEMA directes.' ;


------ 3.3 - EVENT TRIGGER SUR DROP SCHEMA ------

-- Function: z_asgard_admin.asgard_on_drop_schema()

CREATE OR REPLACE FUNCTION z_asgard_admin.asgard_on_drop_schema() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $BODY$
/* Fonction exécutée par le déclencheur sur évènement asgard_on_drop_schema,
qui répercute sur la table de gestion d'Asgard les suppressions de schémas
réalisées par des commandes DROP SCHEMA directes ou dans le cadre de la
suppression d'une extension.

    Elle n'écrit pas directement dans la table z_asgard_admin.gestion_schema,
    mais dans la vue modifiable z_asgard.gestion_schema_etr.

*/
DECLARE
	obj record ;
    objname text ;
    e_mssg text ;
    e_hint text ;
    e_detl text ;
BEGIN
    ------ CONTROLES DES PRIVILEGES ------
    IF NOT has_schema_privilege('z_asgard', 'USAGE')
    THEN
        RAISE EXCEPTION 'EDS1. Schéma z_asgard inaccessible.' ;
    END IF ;
    
    IF NOT has_table_privilege('z_asgard.gestion_schema_etr', 'UPDATE')
        OR NOT has_table_privilege('z_asgard.gestion_schema_etr', 'SELECT')
    THEN
        RAISE EXCEPTION 'EDS2. Permissions insuffisantes pour la vue z_asgard.gestion_schema_etr.' ;
    END IF ;
    
	FOR obj IN SELECT * FROM pg_event_trigger_dropped_objects()
                    WHERE object_type = 'schema'
    LOOP
        ------ ENREGISTREMENT DE LA SUPPRESSION ------
		UPDATE z_asgard.gestion_schema_etr
			SET (creation, oid_schema, ctrl) = (False, NULL, ARRAY['DROP', 'x7-A;#rzo'])
			WHERE quote_ident(nom_schema) = obj.object_identity
            RETURNING nom_schema INTO objname ;    
		IF FOUND THEN
			RAISE NOTICE '... La suppression du schéma % a été enregistrée dans la table de gestion (creation = False).', objname ;
		END IF ;
        
	END LOOP ;
    
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                            e_hint = PG_EXCEPTION_HINT,
                            e_detl = PG_EXCEPTION_DETAIL ;
    RAISE EXCEPTION 'EDS0 > %', e_mssg
        USING DETAIL = e_detl,
            HINT = e_hint ;
               
END
$BODY$ ;

ALTER FUNCTION z_asgard_admin.asgard_on_drop_schema()
    OWNER TO g_admin ;

COMMENT ON FUNCTION z_asgard_admin.asgard_on_drop_schema() IS 'ASGARD. Fonction exécutée par le déclencheur sur évènement asgard_on_drop_schema, qui répercute sur la table de gestion d''Asgard les suppressions de schémas réalisées par des commandes DROP SCHEMA directes ou dans le cadre de la suppression d''une extension.' ;


-- Event Trigger: asgard_on_drop_schema

DROP EVENT TRIGGER asgard_on_drop_schema ;

CREATE EVENT TRIGGER asgard_on_drop_schema ON SQL_DROP
    WHEN TAG IN ('DROP SCHEMA', 'DROP EXTENSION', 'DROP OWNED')
    EXECUTE PROCEDURE z_asgard_admin.asgard_on_drop_schema() ;

COMMENT ON EVENT TRIGGER asgard_on_drop_schema IS 'ASGARD. Déclencheur sur évènement qui répercute sur la table de gestion d''Asgard les suppressions de schémas réalisées par des commandes DROP SCHEMA directes ou dans le cadre de la suppression d''une extension.' ;


------ 3.4 - EVENT TRIGGER SUR CREATE OBJET ------

-- Function: z_asgard_admin.asgard_on_create_objet()

CREATE OR REPLACE FUNCTION z_asgard_admin.asgard_on_create_objet()
    RETURNS event_trigger
    LANGUAGE plpgsql
    AS $BODY$
/* Fonction exécutée par le déclencheur sur évènement asgard_on_create_objet,
qui applique aux nouveaux objets créés les droits pré-définis pour le schéma
dans la table de gestion d'Asgard.

    Elle est activée par toutes les commandes CREATE portant sur des objets qui
    dépendent d'un schéma et ont un propriétaire.

    Elle ignore les objets dont le schéma n'est pas référencé par Asgard.

*/
DECLARE
    obj record ;
    roles record ;
    src record ;
    proprietaire text ;
    xowner text ;
    e_mssg text ;
    e_hint text ;
    e_detl text ;
    l text ;
BEGIN
    ------ CONTROLES DES PRIVILEGES ------
    IF NOT has_schema_privilege('z_asgard', 'USAGE')
    THEN
        RAISE EXCEPTION 'ECO1. Schéma z_asgard inaccessible.' ;
    END IF ;
    
    IF NOT has_table_privilege('z_asgard.gestion_schema_etr', 'SELECT')
    THEN
        RAISE EXCEPTION 'ECO2. Permissions insuffisantes pour la vue z_asgard.gestion_schema_etr.' ;
    END IF ;
    

    FOR obj IN SELECT DISTINCT
        classid, objid, object_type, schema_name, object_identity
        FROM pg_event_trigger_ddl_commands()
        WHERE schema_name IS NOT NULL
        ORDER BY object_type DESC
    LOOP

        -- récupération des rôles de la table de gestion pour le schéma de l'objet
        -- on se base sur les OID et non les noms pour se prémunir contre les changements
        -- de libellés ; des jointures sur pg_roles permettent de vérifier que les rôles
        -- n'ont pas été supprimés entre temps
        SELECT
            r1.rolname AS producteur,
            CASE WHEN editeur = 'public' THEN 'public' ELSE r2.rolname END AS editeur,
            CASE WHEN lecteur = 'public' THEN 'public' ELSE r3.rolname END AS lecteur INTO roles
            FROM z_asgard.gestion_schema_etr
                LEFT JOIN pg_catalog.pg_roles AS r1 ON r1.oid = oid_producteur
                LEFT JOIN pg_catalog.pg_roles AS r2 ON r2.oid = oid_editeur
                LEFT JOIN pg_catalog.pg_roles AS r3 ON r3.oid = oid_lecteur
            WHERE nom_schema = obj.schema_name ;
            
        -- on ne traite que les schémas qui sont gérés par ASGARD
        -- ce qui implique un rôle producteur non nul
        IF roles.producteur IS NOT NULL
        THEN
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
                EXECUTE format('SELECT rolname
                    FROM %2$s LEFT JOIN pg_catalog.pg_roles
                        ON %1$s = pg_roles.oid
                    WHERE %2$s.oid = %3$s',
                    xowner, obj.classid::regclass, obj.objid)
                    INTO STRICT proprietaire ;
                       
                -- si le propriétaire courant n'est pas le producteur
                IF NOT roles.producteur = proprietaire
                THEN
                
                    ------ PROPRIETAIRE DE L'OBJET (DROITS DU PRODUCTEUR) ------
                    RAISE NOTICE 'réattribution de la propriété de % au rôle producteur du schéma :',
                        obj.object_identity ;
                    l := format('ALTER %s %s OWNER TO %I',
                        CASE WHEN obj.object_type = 'statistics object'
                            THEN 'statistics' ELSE obj.object_type END,
                            obj.object_identity, roles.producteur) ;
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
                                AND NOT opfowner = quote_ident(roles.producteur)::regrole
                        )
                    THEN
                        l := format('ALTER operator family %s OWNER TO %I',
                            obj.object_identity, roles.producteur) ;
                        EXECUTE l ;
                        RAISE NOTICE '> %', l ;
                    END IF ;
                    
                END IF ;
                
                ------ DROITS DE L'EDITEUR ------
                IF roles.editeur IS NOT NULL
                THEN
                    -- sur les tables :
                    IF obj.object_type IN ('table', 'view', 'materialized view', 'foreign table')
                    THEN
                        RAISE NOTICE 'application des privilèges standards pour le rôle éditeur du schéma :' ;
                        l := format('GRANT SELECT, UPDATE, DELETE, INSERT ON TABLE %s TO %I',
                            obj.object_identity, roles.editeur) ;
                        EXECUTE l ;
                        RAISE NOTICE '> %', l ;
                        
                    -- sur les séquences :
                    ELSIF obj.object_type IN ('sequence')
                    THEN
                        RAISE NOTICE 'application des privilèges standards pour le rôle éditeur du schéma :' ;
                        l := format('GRANT SELECT, USAGE ON SEQUENCE %s TO %I',
                            obj.object_identity, roles.editeur) ;
                        EXECUTE l ;
                        RAISE NOTICE '> %', l ;
                    END IF ;
                END IF ;
                
                ------ DROITS DU LECTEUR ------
                IF roles.lecteur IS NOT NULL
                THEN
                    -- sur les tables :
                    IF obj.object_type IN ('table', 'view', 'materialized view', 'foreign table')
                    THEN
                        RAISE NOTICE 'application des privilèges standards pour le rôle lecteur du schéma :' ;
                        l := format('GRANT SELECT ON TABLE %s TO %I',
                            obj.object_identity, roles.lecteur) ;
                        EXECUTE l ;
                        RAISE NOTICE '> %', l ;
                        
                    -- sur les séquences :
                    ELSIF obj.object_type IN ('sequence')
                    THEN
                        RAISE NOTICE 'application des privilèges standards pour le rôle lecteur du schéma :' ;
                        l := format('GRANT SELECT ON SEQUENCE %s TO %I',
                            obj.object_identity, roles.lecteur) ;
                        EXECUTE l ;
                        RAISE NOTICE '> %', l ;    
                    END IF ;
                END IF ;
                
                ------ VERIFICATION DES DROITS SUR LES SOURCES DES VUES -------
                IF obj.object_type IN ('view', 'materialized view')
                THEN
                    FOR src IN (
                        SELECT
                            DISTINCT
                            nom_schema,
                            relnamespace,
                            relname,
                            liblg,
                            relowner,
                            oid_producteur,
                            oid_editeur,
                            oid_lecteur
                            FROM pg_catalog.pg_rewrite
                                LEFT JOIN pg_catalog.pg_depend
                                    ON objid = pg_rewrite.oid
                                LEFT JOIN pg_catalog.pg_class
                                    ON pg_class.oid = refobjid
                                LEFT JOIN z_asgard.gestion_schema_etr
                                    ON relnamespace::regnamespace::text = quote_ident(gestion_schema_etr.nom_schema)
                                LEFT JOIN unnest(
                                        ARRAY['Table', 'Table partitionnée', 'Vue', 'Vue matérialisée', 'Table étrangère', 'Séquence'],
                                        ARRAY['r', 'p', 'v', 'm', 'f', 'S']
                                        ) AS t (liblg, libcrt)
                                    ON relkind = libcrt
                            WHERE ev_class = obj.objid
                                AND rulename = '_RETURN'
                                AND ev_type = '1'
                                AND ev_enabled = 'O'
                                AND is_instead
                                AND classid = 'pg_rewrite'::regclass::oid
                                AND refclassid = 'pg_class'::regclass::oid 
                                AND deptype = 'n'
                                AND NOT refobjid = obj.objid
                                AND NOT has_table_privilege(roles.producteur, refobjid, 'SELECT')
                        )
                    LOOP
                        IF src.oid_producteur IS NOT NULL
                        -- l'utilisateur courant a suffisamment de droits pour voir le schéma de la source
                        -- dans sa table de gestion
                        THEN
                            RAISE WARNING 'Le producteur du schéma de la vue % ne dispose pas des droits nécessaires pour accéder à ses données sources.',
                                format('%s %s', CASE WHEN obj.object_type = 'materialized view'
                                    THEN 'matérialisée ' ELSE '' END, obj.object_identity)
                                USING DETAIL = format('%s source %I.%I, producteur %s, éditeur %s, lecteur %s.',
                                    src.liblg, src.nom_schema, src.relname, src.oid_producteur::regrole,
                                    coalesce(src.oid_editeur::regrole::text, 'non défini'),
                                    coalesce(src.oid_lecteur::regrole::text, 'non défini')
                                    ),
                                    HINT = CASE WHEN src.oid_lecteur IS NULL
                                        THEN format('Pour faire du producteur de la vue %s le lecteur du schéma source, vous pouvez lancer la commande suivante : UPDATE z_asgard.gestion_schema_usr SET lecteur = %L WHERE nom_schema = %L.',
                                            CASE WHEN obj.object_type = 'materialized view' THEN 'matérialisée ' ELSE '' END,
                                            roles.producteur, src.nom_schema)
                                        ELSE format('Pour faire du producteur de la vue %s le lecteur du schéma source, vous pouvez lancer la commande suivante : GRANT %s TO %I.',
                                            CASE WHEN obj.object_type = 'materialized view' THEN 'matérialisée ' ELSE '' END,
                                            src.oid_lecteur::regrole, roles.producteur)
                                        END ;
                        ELSE
                            RAISE WARNING 'Le producteur du schéma de la vue % ne dispose pas des droits nécessaires pour accéder à ses données sources.',
                                format('%s %s', CASE WHEN obj.object_type = 'materialized view'
                                    THEN 'matérialisée ' ELSE '' END, obj.object_identity)
                                USING DETAIL =  format('%s source %s.%I, propriétaire %s.', src.liblg,
                                    src.relnamespace::regnamespace, src.relname, src.relowner::regrole) ;
                        END IF ;
                    END LOOP ;            
                END IF ;  
            END IF ;
        END IF ;
    END LOOP ;

EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                            e_hint = PG_EXCEPTION_HINT,
                            e_detl = PG_EXCEPTION_DETAIL ;
    RAISE EXCEPTION 'ECO0 > %', e_mssg
        USING DETAIL = e_detl,
            HINT = e_hint ;
               
END
$BODY$ ;

ALTER FUNCTION z_asgard_admin.asgard_on_create_objet()
    OWNER TO g_admin ;

COMMENT ON FUNCTION z_asgard_admin.asgard_on_create_objet() IS 'ASGARD. Fonction exécutée par le déclencheur sur évènement asgard_on_create_objet, qui applique aux nouveaux objets créés les droits pré-définis pour le schéma dans la table de gestion d''Asgard.' ;


-- Event Trigger: asgard_on_create_objet

DROP EVENT TRIGGER asgard_on_create_objet ;

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


------ 3.5 - EVENT TRIGGER SUR ALTER OBJET ------

-- Function: z_asgard_admin.asgard_on_alter_objet()

CREATE OR REPLACE FUNCTION z_asgard_admin.asgard_on_alter_objet() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $BODY$
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
    (après exécution de la commande) n'est pas référencé par Asgard.

*/
DECLARE
    obj record ;
    n_producteur regrole ;
    a_producteur regrole ;
    l text ;
    e_mssg text ;
    e_hint text ;
    e_detl text ;
    xowner text ;
BEGIN
    ------ CONTROLES DES PRIVILEGES ------
    IF NOT has_schema_privilege('z_asgard', 'USAGE')
    THEN
        RAISE EXCEPTION 'EAO1. Schéma z_asgard inaccessible.' ;
    END IF ;
    
    IF NOT has_table_privilege('z_asgard.gestion_schema_etr', 'SELECT')
    THEN
        RAISE EXCEPTION 'EAO2. Permissions insuffisantes pour la vue z_asgard.gestion_schema_etr.' ;
    END IF ;

    FOR obj IN SELECT DISTINCT
        classid, objid, object_type, schema_name, object_identity
        FROM pg_event_trigger_ddl_commands()
        WHERE schema_name IS NOT NULL
        ORDER BY object_type DESC
    LOOP

        -- récupération du rôle identifié comme producteur pour le schéma de l'objet
        -- (à l'issue de la commande)
        -- on se base sur l'OID et non le nom pour se prémunir contre les changements
        -- de libellés
        SELECT oid_producteur::regrole INTO n_producteur
            FROM z_asgard.gestion_schema_etr
            WHERE nom_schema = obj.schema_name ;
            
        IF FOUND
        THEN
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
                EXECUTE format('SELECT %s::regrole FROM %s WHERE oid = %s',
                    xowner, obj.classid::regclass, obj.objid)
                    INTO STRICT a_producteur ;
                       
                -- si les deux rôles sont différents
                IF NOT n_producteur = a_producteur
                THEN 
                    ------ MODIFICATION DU PROPRIETAIRE ------
                    -- l'objet est attribué au propriétaire désigné pour le schéma
                    -- (n_producteur)
                    RAISE NOTICE 'attribution de la propriété de % au rôle producteur du schéma :',
                        obj.object_identity ;
                    l := format('ALTER %s %s OWNER TO %s',
                        CASE WHEN obj.object_type = 'statistics object'
                            THEN 'statistics' ELSE obj.object_type END,
                            obj.object_identity, n_producteur) ;
                    EXECUTE l ;
                    RAISE NOTICE '> %', l ;    
                END IF ;
            END IF ;
            
        END IF ;
    END LOOP ;

EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                            e_hint = PG_EXCEPTION_HINT,
                            e_detl = PG_EXCEPTION_DETAIL ;
    RAISE EXCEPTION 'EAO0 > %', e_mssg
        USING DETAIL = e_detl,
            HINT = e_hint ;
               
END
$BODY$ ;

ALTER FUNCTION z_asgard_admin.asgard_on_alter_objet()
    OWNER TO g_admin ;

COMMENT ON FUNCTION z_asgard_admin.asgard_on_alter_objet() IS 'ASGARD. Fonction exécutée par le déclencheur sur évènement asgard_on_alter_objet, qui assure que le producteur d''un schéma reste propriétaire de tous les objets qui en dépendent.' ;


-- Event Trigger: asgard_on_alter_objet

DROP EVENT TRIGGER asgard_on_alter_objet ;

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

---------------------------------------
------ 4 - FONCTIONS UTILITAIRES ------
---------------------------------------

/* 4.3 - MODIFICATION DU PROPRIETAIRE D'UN SCHEMA ET SON CONTENU
   4.5 - INITIALISATION DE GESTION_SCHEMA
   4.8 - REINITIALISATION DES PRIVILEGES SUR UN SCHEMA
   4.9 - REINITIALISATION DES PRIVILEGES SUR UN OBJET
   4.10 - DEPLACEMENT D'OBJET
   4.11 - OCTROI D'UN RÔLE À TOUS LES RÔLES DE CONNEXION
   4.15 - TRANSFORMATION D'UN NOM DE RÔLE POUR COMPARAISON AVEC LES CHAMPS ACL
   4.16 - DIAGNOSTIC DES DROITS NON STANDARDS */


------ 4.3 - MODIFICATION DU PROPRIETAIRE D'UN SCHEMA ET SON CONTENU ------

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

*/
DECLARE
    item record ;
    k int := 0 ;
    o_owner oid ;
    s_owner text ;
BEGIN
    ------ TESTS PREALABLES ------
    SELECT nspowner::regrole::text
        INTO s_owner
        FROM pg_catalog.pg_namespace
        WHERE nspname = n_schema ;
    
    -- non existance du schémas
    IF NOT FOUND
    THEN
        RAISE EXCEPTION 'FAP1. Le schéma % n''existe pas.', n_schema ;
    END IF ;
    
    -- absence de permission sur le propriétaire courant du schéma
    IF NOT pg_has_role(s_owner::regrole::oid, 'USAGE')
    THEN
        RAISE EXCEPTION 'FAP5. Vous n''êtes pas habilité à modifier le propriétaire du schéma %.', n_schema
            USING DETAIL = format('Propriétaire courant : %s.', s_owner) ;  
    END IF ;
    
    -- le propriétaire désigné n'existe pas
    IF NOT n_owner IN (SELECT rolname FROM pg_catalog.pg_roles)
    THEN
        RAISE EXCEPTION 'FAP2. Le rôle % n''existe pas.', n_owner ;
    -- absence de permission sur le propriétaire désigné
    ELSIF NOT pg_has_role(n_owner, 'USAGE')
    THEN
        RAISE EXCEPTION 'FAP6. Vous n''avez pas la permission d''utiliser le rôle %.', n_owner ;  
    ELSE
        o_owner := quote_ident(n_owner)::regrole::oid ;
    END IF ;
    
    -- le propriétaire désigné n'est pas le propriétaire courant et la fonction
    -- a été lancée avec la variante qui ne traite pas le schéma
    IF NOT b_setschema
            AND NOT quote_ident(n_owner) = s_owner
    THEN
        RAISE EXCEPTION 'FAP3. Le rôle % n''est pas propriétaire du schéma.', n_owner
            USING HINT = format('Lancez asgard_admin_proprietaire(%L, %L) pour changer également le propriétaire du schéma.',
                n_schema, n_owner) ;
    END IF ;
    
    ------ PROPRIÉTAIRE DU SCHEMA ------
    IF b_setschema
    THEN
        EXECUTE format('ALTER SCHEMA %I OWNER TO %I', n_schema, n_owner) ;
        RAISE NOTICE '> %', format('ALTER SCHEMA %I OWNER TO %I', n_schema, n_owner) ;
        k := k + 1 ;
    END IF ;
    
    ------ PROPRIETAIRES DES OBJETS ------
    -- uniquement ceux qui n'appartiennent pas déjà
    -- au rôle identifié
    FOR item IN
        -- tables, tables étrangères, vues, vues matérialisées,
        -- partitions, séquences :
        SELECT
            relname::text AS n_objet,
            relowner AS obj_owner,
            relkind IN ('r', 'f', 'p', 'm') AS b,
            -- b servira à assurer que les tables soient listées avant les
            -- objets qui en dépendent
            format('ALTER %s %s OWNER TO %I',
                kind_lg, pg_class.oid::regclass, n_owner) AS commande
            FROM pg_catalog.pg_class,
                unnest(ARRAY['r', 'p', 'v', 'm', 'f', 'S'],
                       ARRAY['TABLE', 'TABLE', 'VIEW', 'MATERIALIZED VIEW', 'FOREIGN TABLE', 'SEQUENCE']) AS l (kind_crt, kind_lg)
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
            proowner AS obj_owner,
            False AS b,
            format('ALTER %s %s OWNER TO %I',
                CASE WHEN current_setting('server_version_num')::int < 110000
                    THEN 'FUNCTION' ELSE 'ROUTINE' END,
                pg_proc.oid::regprocedure, n_owner) AS commande
            FROM pg_catalog.pg_proc
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
            typowner AS obj_owner,
            False AS b,
            format('ALTER %s %I.%I OWNER TO %I',
                kind_lg, n_schema, typname, n_owner) AS commande
            FROM unnest(ARRAY['true', 'false'],
                       ARRAY['DOMAIN', 'TYPE']) AS l (kind_crt, kind_lg),
                pg_catalog.pg_type
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
            conowner AS obj_owner,
            False AS b,
            format('ALTER CONVERSION %I.%I OWNER TO %I',
                n_schema, conname, n_owner) AS commande
            FROM pg_catalog.pg_conversion
            WHERE connamespace = quote_ident(n_schema)::regnamespace
                AND NOT conowner = o_owner
        UNION
        -- opérateurs :
        SELECT
            oprname::text AS n_objet,
            oprowner AS obj_owner,
            False AS b,
            format('ALTER OPERATOR %s OWNER TO %I',
                pg_operator.oid::regoperator, n_owner) AS commande
            FROM pg_catalog.pg_operator
            WHERE oprnamespace = quote_ident(n_schema)::regnamespace
                AND NOT oprowner = o_owner
        UNION
        -- collations :
        SELECT
            collname::text AS n_objet,
            collowner AS obj_owner,
            False AS b,
            format('ALTER COLLATION %I.%I OWNER TO %I',
                n_schema, collname, n_owner) AS commande
            FROM pg_catalog.pg_collation
            WHERE collnamespace = quote_ident(n_schema)::regnamespace
                AND NOT collowner = o_owner
        UNION
        -- text search dictionary :
        SELECT
            dictname::text AS n_objet,
            dictowner AS obj_owner,
            False AS b,
            format('ALTER TEXT SEARCH DICTIONARY %s OWNER TO %I',
                pg_ts_dict.oid::regdictionary, n_owner) AS commande
            FROM pg_catalog.pg_ts_dict
            WHERE dictnamespace = quote_ident(n_schema)::regnamespace
                AND NOT dictowner = o_owner
        UNION
        -- text search configuration :
        SELECT
            cfgname::text AS n_objet,
            cfgowner AS obj_owner,
            False AS b,
            format('ALTER TEXT SEARCH CONFIGURATION %s OWNER TO %I',
                pg_ts_config.oid::regconfig, n_owner) AS commande
            FROM pg_catalog.pg_ts_config
            WHERE cfgnamespace = quote_ident(n_schema)::regnamespace
                AND NOT cfgowner = o_owner
        -- operator family :
        UNION
        SELECT
            opfname::text AS n_objet,
            opfowner AS obj_owner,
            False AS b,
            format('ALTER OPERATOR FAMILY %I.%I USING %I OWNER TO %I',
                n_schema, opfname, amname, n_owner) AS commande
            FROM pg_catalog.pg_opfamily
                LEFT JOIN pg_catalog.pg_am ON pg_am.oid = opfmethod
            WHERE opfnamespace = quote_ident(n_schema)::regnamespace
                AND NOT opfowner = o_owner
        -- operator class :
        UNION
        SELECT
            opcname::text AS n_objet,
            opcowner AS obj_owner,
            False AS b,
            format('ALTER OPERATOR CLASS %I.%I USING %I OWNER TO %I',
                n_schema, opcname, amname, n_owner) AS commande
            FROM pg_catalog.pg_opclass
                LEFT JOIN pg_catalog.pg_am ON pg_am.oid = opcmethod
            WHERE opcnamespace = quote_ident(n_schema)::regnamespace
                AND NOT opcowner = o_owner
            ORDER BY b DESC
    LOOP
        IF pg_has_role(item.obj_owner, 'USAGE')
        THEN
            EXECUTE item.commande ;
            RAISE NOTICE '> %', item.commande ;
            k := k + 1 ;
        ELSE
            RAISE EXCEPTION 'FAP4. Vous n''êtes pas habilité à modifier le propriétaire de l''objet %.', item.n_objet
                USING DETAIL = format('Propriétaire courant : %s.', item.obj_owner::regrole) ;    
        END IF ;
    END LOOP ;
    
    ------ CATALOGUES CONDITIONNELS ------
    -- soit ceux qui n'existent pas sous toutes les versions de PostgreSQL    
    IF current_setting('server_version_num')::int >= 100000
    THEN
        FOR item IN
            -- extended planner statistics :
            SELECT
                stxname::text AS n_objet,
                stxowner AS obj_owner,
                format('ALTER STATISTICS %I.%I OWNER TO %I',
                    n_schema, stxname, n_owner) AS commande
                FROM pg_catalog.pg_statistic_ext
                WHERE stxnamespace = quote_ident(n_schema)::regnamespace
                    AND NOT stxowner = o_owner        
        LOOP
            IF pg_has_role(item.obj_owner, 'USAGE')
            THEN
                EXECUTE item.commande ;
                RAISE NOTICE '> %', item.commande ;
                k := k + 1 ;
            ELSE
                RAISE EXCEPTION 'FAP4. Vous n''êtes pas habilité à modifier le propriétaire de l''objet %.', item.n_objet
                    USING DETAIL = format('Propriétaire courant : %s.', item.obj_owner::regrole) ;    
            END IF ;
        END LOOP ;
    END IF ;

    ------ RESULTAT ------
    RETURN k ;
END
$_$ ;

ALTER FUNCTION z_asgard.asgard_admin_proprietaire(text, text, boolean)
    OWNER TO g_admin_ext ;

COMMENT ON FUNCTION z_asgard.asgard_admin_proprietaire(text, text, boolean) IS 'ASGARD. Attribue un schéma et tous les objets qu''il contient au propriétaire désigné.' ;


------ 4.5 - INITIALISATION DE GESTION_SCHEMA ------

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

*/
DECLARE
    item record ;
    e_mssg text ;
    e_detl text ;
    e_hint text ;
    b_creation boolean ;
BEGIN

    FOR item IN SELECT nspname, nspowner, rolname
        FROM pg_catalog.pg_namespace
            LEFT JOIN pg_catalog.pg_roles ON pg_roles.oid = nspowner
        WHERE NOT nspname ~ ANY(ARRAY['^pg_toast', '^pg_temp', '^pg_catalog$',
                                '^public$', '^information_schema$', '^topology$'])
            AND (exceptions IS NULL OR NOT nspname = ANY(exceptions))
    LOOP
        SELECT creation INTO b_creation
            FROM z_asgard.gestion_schema_usr
            WHERE item.nspname = nom_schema ;
        IF b_creation IS NULL
        -- schéma non référencé dans gestion_schema
        THEN
            INSERT INTO z_asgard.gestion_schema_usr (nom_schema, producteur, creation)
                VALUES (item.nspname, item.rolname, True) ;
            RAISE NOTICE '... Schéma % enregistré dans la table de gestion.', item.nspname ;
        ELSIF NOT b_creation
        -- schéma pré-référencé dans gestion_schema
        THEN
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
        END IF ;
    END LOOP ;

    RETURN '__ FIN INITALISATION.' ;

EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                            e_hint = PG_EXCEPTION_HINT,
                            e_detl = PG_EXCEPTION_DETAIL ;           
    RAISE EXCEPTION 'FIG0 > %', e_mssg
        USING DETAIL = e_detl,
            HINT = e_hint ;

END
$_$ ;

ALTER FUNCTION z_asgard_admin.asgard_initialisation_gestion_schema(text[], boolean)
    OWNER TO g_admin ;

COMMENT ON FUNCTION z_asgard_admin.asgard_initialisation_gestion_schema(text[], boolean) IS 'ASGARD. Enregistre dans la table de gestion d''Asgard l''ensemble des schémas existants encore non référencés, hors schémas système et ceux qui sont (optionnellement) listés en argument.' ;


------ 4.8 - REINITIALISATION DES PRIVILEGES SUR UN SCHEMA ------

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

    Si cette fonction est appliquée à un schéma existant non référencé
    dans la table de gestion, elle l'y ajoute, avec son propriétaire
    courant comme producteur.

    La fonction échouera si le schéma n'existe pas.

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

*/
DECLARE
    roles record ;
    cree boolean ;
    r record ;
    c record ;
    item record ;
    n_owner text ;
    k int := 0 ;
    n int ;
    e_mssg text ;
    e_detl text ;
    e_hint text ;
BEGIN
    ------ TESTS PREALABLES ------
    -- schéma système
    IF n_schema ~ ANY(ARRAY['^pg_toast', '^pg_temp', '^pg_catalog$',
                            '^public$', '^information_schema$', '^topology$'])
    THEN
        RAISE EXCEPTION 'FIS1. Opération interdite. Le schéma % est un schéma système.', n_schema ;
    END IF ;
    
    -- existence du schéma
    SELECT rolname INTO n_owner
        FROM pg_catalog.pg_namespace
            LEFT JOIN pg_catalog.pg_roles ON pg_roles.oid = nspowner
        WHERE n_schema = nspname ;
    IF NOT FOUND
    THEN
        RAISE EXCEPTION 'FIS2. Echec. Le schéma % n''existe pas.', n_schema ;
    END IF ;
    
    -- permission sur le propriétaire
    IF NOT pg_has_role(n_owner, 'USAGE')
    THEN
        RAISE EXCEPTION 'FIS3. Echec. Vous ne disposez pas des permissions nécessaires sur le schéma % pour réaliser cette opération.', n_schema
            USING HINT = format('Il vous faut être membre du rôle propriétaire %s.', n_owner) ;
    END IF ;
    
    ------ SCHEMA DEJA REFERENCE ? ------
    SELECT
        creation
        INTO cree
        FROM z_asgard.gestion_schema_usr
        WHERE nom_schema = n_schema ;
    
    ------ SCHEMA NON REFERENCE ------
    -- ajouté à gestion_schema
    -- le reste est pris en charge par le trigger
    -- on_modify_gestion_schema_after
    IF NOT FOUND
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
    ELSIF NOT cree
    THEN
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
        
        IF b_preserve
        THEN
            RETURN '__ INITIALISATION REUSSIE.' ;
        END IF ;
    END IF ;
        
    ------ RECUPERATION DES ROLES ------
    SELECT
        r1.rolname AS producteur,
        CASE WHEN editeur = 'public' THEN 'public' ELSE r2.rolname END AS editeur,
        CASE WHEN lecteur = 'public' THEN 'public' ELSE r3.rolname END AS lecteur
        INTO roles
        FROM z_asgard.gestion_schema_etr
            LEFT JOIN pg_catalog.pg_roles AS r1 ON r1.oid = oid_producteur
            LEFT JOIN pg_catalog.pg_roles AS r2 ON r2.oid = oid_editeur
            LEFT JOIN pg_catalog.pg_roles AS r3 ON r3.oid = oid_lecteur
        WHERE nom_schema = n_schema ;
        
    ------ REMISE A PLAT DES PROPRIETAIRES ------
    -- uniquement pour les schémas qui étaient déjà
    -- référencés dans gestion_schema (pour les autres, pris en charge
    -- par le trigger on_modify_gestion_schema_after)
    
    -- schéma dont le propriétaire ne serait pas le producteur
    IF cree
    THEN
        IF NOT roles.producteur = n_owner
        THEN
            -- permission sur le producteur
            IF NOT pg_has_role(roles.producteur, 'USAGE')
            THEN
                RAISE EXCEPTION 'FIS4. Echec. Vous ne disposez pas des permissions nécessaires sur le schéma % pour réaliser cette opération.', n_schema
                    USING HINT = format('Il vous faut être membre du rôle producteur %s.') ;
            END IF ;
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
        
    END IF ;
    
    ------ ACL PAR DEFAUT ------
    k := 0 ;
    RAISE NOTICE 'suppression des privilèges par défaut :' ;
    FOR item IN (
        SELECT
            format(
                'ALTER DEFAULT PRIVILEGES FOR ROLE %s IN SCHEMA %s REVOKE %s ON %s FROM %s',
                defaclrole::regrole,
                defaclnamespace::regnamespace,
                -- impossible que defaclnamespace vaille 0 (privilège portant
                -- sur tous les schémas) ici, puisque c'est l'OID de n_schema
                privilege,
                typ_lg,
                CASE WHEN grantee = 0 THEN 'public' ELSE grantee::regrole::text END
                ) AS commande,
            pg_has_role(defaclrole, 'USAGE') AS utilisable,
            defaclrole
            FROM pg_default_acl,
                aclexplode(defaclacl) AS acl (grantor, grantee, privilege, grantable),
                unnest(ARRAY['TABLES', 'SEQUENCES',
                        CASE WHEN current_setting('server_version_num')::int < 110000
                            THEN 'FUNCTIONS' ELSE 'ROUTINES' END,
                        -- à ce stade FUNCTIONS et ROUTINES sont équivalents, mais
                        -- ROUTINES est préconisé
                        'TYPES', 'SCHEMAS'],
                    ARRAY['r', 'S', 'f', 'T', 'n']) AS t (typ_lg, typ_crt)
            WHERE defaclnamespace = quote_ident(n_schema)::regnamespace
                AND defaclobjtype = typ_crt
        )
    LOOP          
        IF item.utilisable
        THEN
            EXECUTE item.commande ;
            RAISE NOTICE '> %', item.commande ;
        ELSE
            RAISE EXCEPTION 'FIS6. Echec. Vous n''avez pas les privilèges nécessaires pour modifier les privilèges par défaut alloués par le rôle %.', item.defaclrole::regrole::text
                USING DETAIL = item.commande,
                    HINT = 'Tentez de relancer la fonction en tant que super-utilisateur.' ;
        END IF ;
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
                            e_detl = PG_EXCEPTION_DETAIL ;
    RAISE EXCEPTION 'FIS0 > %', e_mssg
        USING DETAIL = e_detl,
            HINT = e_hint ;
    
END
$_$ ;

ALTER FUNCTION z_asgard.asgard_initialise_schema(text, boolean, boolean)
    OWNER TO g_admin_ext ;

COMMENT ON FUNCTION z_asgard.asgard_initialise_schema(text, boolean, boolean) IS 'ASGARD. Réinitialise les droits sur un schéma et ses objets selon les privilèges standards du producteur, de l''éditeur et du lecteur désignés dans la table de gestion d''Asgard.' ;


------ 4.9 - REINITIALISATION DES PRIVILEGES SUR UN OBJET ------

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

    Parameters
    ----------
    obj_schema : text
        Le nom du schéma contenant l'objet.
    obj_nom : text
        Le nom de l'objet. À écrire sans les guillemets des identifiants
        PostgreSQL SAUF pour les fonctions, dont le nom doit impérativement
        être entre guillemets s'il ne respecte pas les conventions de
        nommage des identifiants PostgreSQL.
    obj_typ : str
        Le type de l'objet, parmi 'table', 'partitioned table' (assimilé
        à 'table'), 'view', 'materialized view', 'foreign table', 'sequence',
        'function', 'aggregate', 'procedure', 'routine', 'type' et 'domain'.

    Returns
    -------
    text
        '__ REINITIALISATION REUSSIE.' si la requête s'est exécutée normalement.

*/
DECLARE
    class_info record ;
    roles record ;
    obj record ;
    r record ;
    c record ;
    l text ;
    k int := 0 ;
BEGIN

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
    IF obj_schema ~ ANY(ARRAY['^pg_toast', '^pg_temp', '^pg_catalog$',
                            '^public$', '^information_schema$', '^topology$'])
    THEN
        RAISE EXCEPTION 'FIO1. Opération interdite. Le schéma % est un schéma système.', obj_schema ;
    END IF ;
    
    -- schéma non référencé
    IF NOT obj_schema IN (SELECT nom_schema FROM z_asgard.gestion_schema_usr WHERE creation)
    THEN
        RAISE EXCEPTION 'FIO2. Echec. Le schéma % n''est pas référencé dans la table de gestion (ou marqué comme non créé).', obj_schema ;
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
            USING HINT = 'Types acceptés : ''table'', ''partitioned table'', ''view'', ''materialized view'', ''foreign table'', ''sequence'', ''function'', ''aggregate'', ''routine'', ''procedure'', ''type'', ''domain''.' ;
    END IF ;
        
    -- objet inexistant + récupération du propriétaire
    EXECUTE 'SELECT ' || class_info.xowner || '::regrole::text AS prop, '
            || class_info.xclass || '.oid, '
            || CASE WHEN class_info.xclass = 'pg_type'
                    THEN quote_literal(quote_ident(obj_schema) || '.' || quote_ident(obj_nom)) || '::text'
                ELSE class_info.xclass || '.oid::' || class_info.xreg || '::text'
                END || ' AS appel'
            || ' FROM pg_catalog.' || class_info.xclass
            || ' WHERE ' || CASE WHEN class_info.xclass = 'pg_proc'
                    THEN class_info.xclass || '.oid = '
                        || quote_literal(quote_ident(obj_schema) || '.' || obj_nom)
                        || '::regprocedure'
                ELSE class_info.xname || ' = ' || quote_literal(obj_nom)
                    || ' AND ' || class_info.xschema || '::regnamespace::text = '
                    || quote_literal(quote_ident(obj_schema)) END
        INTO obj ;
            
    IF obj.prop IS NULL
    THEN
        RAISE EXCEPTION 'FIO4. Echec. L''objet % n''existe pas.', obj_nom ;
    END IF ;    
    
    ------ RECUPERATION DES ROLES ------
    SELECT
        r1.rolname AS producteur,
        CASE WHEN editeur = 'public' THEN 'public' ELSE r2.rolname END AS editeur,
        CASE WHEN lecteur = 'public' THEN 'public' ELSE r3.rolname END AS lecteur,
        creation INTO roles
        FROM z_asgard.gestion_schema_etr
            LEFT JOIN pg_catalog.pg_roles AS r1 ON r1.oid = oid_producteur
            LEFT JOIN pg_catalog.pg_roles AS r2 ON r2.oid = oid_editeur
            LEFT JOIN pg_catalog.pg_roles AS r3 ON r3.oid = oid_lecteur
        WHERE nom_schema = obj_schema ;
            
    -- permission sur le producteur
    IF NOT pg_has_role(roles.producteur, 'USAGE')
    THEN
        RAISE EXCEPTION 'FIO5. Echec. Vous ne disposez pas des permissions nécessaires sur le schéma % pour réaliser cette opération.', obj_schema
            USING HINT = format('Il vous faut être membre du rôle producteur %s.', roles.producteur) ;
    END IF ;
    
    ------ REMISE A PLAT DU PROPRIETAIRE ------
    IF NOT obj.prop = quote_ident(roles.producteur)
    THEN
        -- permission sur le propriétaire de l'objet
        IF NOT pg_has_role(obj.prop::regrole::oid, 'USAGE')
        THEN
            RAISE EXCEPTION 'FIO6. Echec. Vous ne disposez pas des permissions nécessaires sur l''objet % pour réaliser cette opération.', obj_nom
                USING HINT = format('Il vous faut être membre du rôle propriétaire de l''objet (%s).', obj.prop) ;
        END IF ;
        
        RAISE NOTICE 'réattribution de la propriété de % au rôle producteur du schéma :', obj_nom ;
        l := format('ALTER %s %s OWNER TO %I', obj_typ, obj.appel, roles.producteur) ;
        EXECUTE l ;
        RAISE NOTICE '> %', l ;
    END IF ;    
    
    ------ DESTRUCTION DES PRIVILEGES ACTUELS ------
    -- hors privilèges par défaut (définis par ALTER DEFAULT PRIVILEGE)
    -- et hors révocations des privilèges par défaut de public sur
    -- les types et les fonctions
    -- pour le propriétaire, ces commandes ont pour effet
    -- de remettre les privilèges par défaut supprimés
    
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
                
    RETURN '__ REINITIALISATION REUSSIE.' ;
END
$_$;

ALTER FUNCTION z_asgard.asgard_initialise_obj(text, text, text)
    OWNER TO g_admin_ext ;

COMMENT ON FUNCTION z_asgard.asgard_initialise_obj(text, text, text) IS 'ASGARD. Réinitialise les privilèges sur un objet.' ;


------ 4.10 - DEPLACEMENT D'OBJET ------

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
    obj_typ : str
        Le type de l'objet, parmi 'table', 'partitioned table' (assimilé
        à 'table'), 'view', 'materialized view', 'foreign table', 'sequence',
        'function', 'aggregate', 'procedure', 'routine', 'type' et 'domain'.
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
    IF obj_schema ~ ANY(ARRAY['^pg_toast', '^pg_temp', '^pg_catalog$',
                            '^public$', '^information_schema$', '^topology$'])
    THEN
        RAISE EXCEPTION 'FDO1. Opération interdite. Le schéma % est un schéma système.', obj_schema ;
    END IF ;
    
    -- schéma de départ non référencé
    IF NOT obj_schema IN (SELECT nom_schema FROM z_asgard.gestion_schema_usr WHERE creation)
    THEN
        RAISE EXCEPTION 'FDO2. Echec. Le schéma % n''est pas référencé dans la table de gestion (ou marqué comme non créé).', obj_schema ;
    END IF ;
    
    -- schéma cible non référencé
    IF NOT schema_cible IN (SELECT nom_schema FROM z_asgard.gestion_schema_usr WHERE creation)
    THEN
        RAISE EXCEPTION 'FDO3. Echec. Le schéma cible % n''est pas référencé dans la table de gestion (ou marqué comme non créé).', schema_cible ;
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
            USING HINT = 'Types acceptés : ''table'', ''partitioned table'', ''view'', ''materialized view'', ''foreign table'', ''sequence'', ''function'', ''aggregate'', ''procedure'', ''routine'', ''type'', ''domain''.' ;
    END IF ;
    
    -- objet inexistant + récupération du propriétaire
    EXECUTE 'SELECT ' || class_info.xowner || '::regrole::text AS prop, '
            || class_info.xclass || '.oid, '
            || CASE WHEN class_info.xclass = 'pg_type'
                    THEN quote_literal(quote_ident(obj_schema) || '.' || quote_ident(obj_nom)) || '::text'
                ELSE class_info.xclass || '.oid::' || class_info.xreg || '::text'
                END || ' AS appel,'
            || class_info.xname || ' AS objname'
            || CASE WHEN class_info.xclass = 'pg_proc'
                THEN ', pg_catalog.oidvectortypes(proargtypes) AS proargtypes' ELSE '' END
            || ' FROM pg_catalog.' || class_info.xclass
            || ' WHERE ' || CASE WHEN class_info.xclass = 'pg_proc'
                    THEN class_info.xclass || '.oid = '
                        || quote_literal(quote_ident(obj_schema) || '.' || obj_nom)
                        || '::regprocedure'
                ELSE class_info.xname || ' = ' || quote_literal(obj_nom)
                    || ' AND ' || class_info.xschema || '::regnamespace::text = '
                    || quote_literal(quote_ident(obj_schema)) END
        INTO obj ;
    
    IF obj.prop IS NULL
    THEN
        RAISE EXCEPTION 'FDO5. Echec. L''objet % n''existe pas.', obj_nom ;
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
        RAISE EXCEPTION 'FDO8. Opération interdite. Il existe déjà un objet de même définition dans le schéma cible.' ;
    END IF ;
    
    ------ RECUPERATION DES ROLES ------
    -- schéma de départ :
    SELECT
        r1.rolname AS producteur,
        CASE WHEN editeur = 'public' THEN 'public' ELSE r2.rolname END AS editeur,
        CASE WHEN lecteur = 'public' THEN 'public' ELSE r3.rolname END AS lecteur,
        creation INTO roles
        FROM z_asgard.gestion_schema_etr
            LEFT JOIN pg_catalog.pg_roles AS r1 ON r1.oid = oid_producteur
            LEFT JOIN pg_catalog.pg_roles AS r2 ON r2.oid = oid_editeur
            LEFT JOIN pg_catalog.pg_roles AS r3 ON r3.oid = oid_lecteur
        WHERE nom_schema = obj_schema ;
        
    -- schéma cible :
    SELECT
        r1.rolname AS producteur,
        CASE WHEN editeur = 'public' THEN 'public' ELSE r2.rolname END AS editeur,
        CASE WHEN lecteur = 'public' THEN 'public' ELSE r3.rolname END AS lecteur,
        creation INTO roles_cible
        FROM z_asgard.gestion_schema_etr
            LEFT JOIN pg_catalog.pg_roles AS r1 ON r1.oid = oid_producteur
            LEFT JOIN pg_catalog.pg_roles AS r2 ON r2.oid = oid_editeur
            LEFT JOIN pg_catalog.pg_roles AS r3 ON r3.oid = oid_lecteur
        WHERE nom_schema = schema_cible ;
            
    -- permission sur le producteur du schéma cible
    IF NOT pg_has_role(roles_cible.producteur, 'USAGE')
    THEN
        RAISE EXCEPTION 'FDO6. Echec. Vous ne disposez pas des permissions nécessaires sur le schéma cible % pour réaliser cette opération.', schema_cible
            USING HINT = format('Il vous faut être membre du rôle producteur %s.', roles_cible.producteur) ;
    END IF ;
    
    -- permission sur le propriétaire de l'objet
    IF NOT pg_has_role(obj.prop::regrole::oid, 'USAGE')
    THEN
        RAISE EXCEPTION 'FDO7. Echec. Vous ne disposez pas des permissions nécessaires sur l''objet % pour réaliser cette opération.', obj_nom
            USING HINT = format('Il vous faut être membre du rôle propriétaire de l''objet (%s).', obj.prop) ;
    END IF ;
    
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
            RAISE EXCEPTION 'FDO9. Opération interdite. Il existe dans le schéma cible une relation de même nom que l''index associé %.', s.relname ;
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
            RAISE EXCEPTION 'FDO10. Opération interdite. Il existe dans le schéma cible une relation de même nom que l''index associé %.', s.relname ;
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
                RAISE EXCEPTION 'FDO11. Opération interdite. Il existe dans le schéma cible une relation de même nom que la séquence associée %.', s.relname ;
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
    EXECUTE format('ALTER %s %s SET SCHEMA %I', obj_typ, obj.appel, schema_cible) ;
                
    RAISE NOTICE '... Objet déplacé dans le schéma %.', schema_cible ;
  
    ------ PRIVILEGES DU PRODUCTEUR ------
    -- par défaut, ils ont été transférés
    -- lors du changement de propriétaire, il
    -- n'y a donc qu'à réinitialiser pour les
    -- variantes 2 et 6
    
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

    RETURN '__ DEPLACEMENT REUSSI.' ;
END
$_$ ;

ALTER FUNCTION z_asgard.asgard_deplace_obj(text, text, text, text, int)
    OWNER TO g_admin_ext ;

COMMENT ON FUNCTION z_asgard.asgard_deplace_obj(text, text, text, text, int) IS 'ASGARD. Déplace un objet vers un nouveau schéma, en transférant ou réinitialisant les privilèges selon la variante choisie.' ;


------ 4.11 - OCTROI D'UN RÔLE À TOUS LES RÔLES DE CONNEXION ------

-- Function: z_asgard_admin.asgard_all_login_grant_role(text, boolean)

CREATE OR REPLACE FUNCTION z_asgard_admin.asgard_all_login_grant_role(n_role text, b boolean DEFAULT True)
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

*/
DECLARE
    roles record ;
    attributeur text ;
    utilisateur text := current_user ;
    c text ;
    n int := 0 ;
BEGIN
    ------ TESTS PREALABLES -----
    -- existance du rôle
    IF NOT n_role IN (SELECT rolname FROM pg_catalog.pg_roles)
    THEN
        RAISE EXCEPTION 'FLG1. Echec. Le rôle % n''existe pas.', n_role ;
    END IF ;
    
    -- on cherche un rôle dont l'utilisateur est
    -- membre et qui, soit a l'attribut CREATEROLE
    -- soit a ADMIN OPTION sur le rôle
    SELECT rolname INTO attributeur
        FROM pg_roles
        WHERE pg_has_role(rolname, 'MEMBER') AND rolcreaterole
        ORDER BY rolname = current_user DESC ;
    IF NOT FOUND
    THEN
        SELECT grantee INTO attributeur
            FROM information_schema.applicable_roles
            WHERE is_grantable = 'YES' AND role_name = n_role ;
        IF NOT FOUND
        THEN
            RAISE EXCEPTION 'FLG2. Opération interdite. Permissions insuffisantes pour le rôle %.', n_role
                USING HINT = format('Votre rôle doit être membre de %s avec admin option ou disposer de l''attribut CREATEROLE pour réaliser cette opération.',
                    n_role) ;
        END IF ;
    END IF ;
    
    EXECUTE format('SET ROLE %I', attributeur) ;
    
    IF b
    THEN
        FOR roles IN SELECT rolname
            FROM pg_roles LEFT JOIN pg_auth_members
                ON member = pg_roles.oid AND roleid = n_role::regrole::oid
            WHERE rolcanlogin AND member IS NULL
                AND NOT rolsuper
        LOOP
            c := format('GRANT %s TO %s', n_role, roles.rolname) ;
            EXECUTE c ;
            RAISE NOTICE '> %', c ;
            n := n + 1 ;
        END LOOP ;
    ELSE
        FOR roles IN SELECT rolname FROM pg_roles
            WHERE rolcanlogin AND NOT pg_has_role(rolname, n_role, 'MEMBER')
        LOOP
            c := format('GRANT %s TO %s', n_role, roles.rolname) ;
            EXECUTE c ;
            RAISE NOTICE '> %', c ;
            n := n + 1 ;
        END LOOP ;
    END IF ;
    
    EXECUTE format('SET ROLE %I', utilisateur) ;
    
    RETURN n ;
END
$_$;

ALTER FUNCTION z_asgard_admin.asgard_all_login_grant_role(text, boolean)
    OWNER TO g_admin ;

COMMENT ON FUNCTION z_asgard_admin.asgard_all_login_grant_role(text, boolean) IS 'ASGARD. Confère à tous les rôles de connexion du serveur l''appartenance au rôle donné en argument.' ;


------ 4.15 - TRANSFORMATION D'UN NOM DE RÔLE POUR COMPARAISON AVEC LES CHAMPS ACL ------

-- Function: z_asgard.asgard_role_trans_acl(regrole)

DROP FUNCTION z_asgard.asgard_role_trans_acl(regrole) ;


------ 4.16 - DIAGNOSTIC DES DROITS NON STANDARDS ------

-- Function: z_asgard_admin.asgard_diagnostic(text[])

CREATE OR REPLACE FUNCTION z_asgard_admin.asgard_diagnostic(cibles text[] DEFAULT NULL::text[])
    RETURNS TABLE (nom_schema text, nom_objet text, typ_objet text, critique boolean, anomalie text)
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
    
*/
DECLARE
    item record ;
    catalogue record ;
    objet record ;
    asgard record ;
    s text ;
    cibles_trans text ;
BEGIN

    ------ CONTROLES ET PREPARATION ------
    cibles := nullif(nullif(cibles, ARRAY[]::text[]), ARRAY[NULL]::text[]) ;
    
    IF cibles IS NOT NULL
    THEN
        
        FOREACH s IN ARRAY cibles
        LOOP
            IF NOT s IN (SELECT gestion_schema_etr.nom_schema FROM z_asgard.gestion_schema_etr WHERE gestion_schema_etr.creation)
            THEN
                RAISE EXCEPTION 'FDD1. Le schéma % n''existe pas ou n''est pas référencé dans la table de gestion d''ASGARD.', s ;
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
                    ARRAY['rawdDxt', 'rawdDxt', 'rawdDxt', 'rawdDxt', 'rawdDxt', 'rwU',
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
                                    ('z_asgard_admin', 'z_asgard_admin', 'schéma', 'g_admin_ext', 'U'),
                                    ('z_asgard_admin', 'gestion_schema', 'table', 'g_admin_ext', 'rawd'),
                                    ('z_asgard', 'z_asgard', 'schéma', 'public', 'U'),
                                    ('z_asgard', 'gestion_schema_usr', 'vue', 'public', 'rawd'),
                                    ('z_asgard', 'gestion_schema_etr', 'vue', 'public', 'rawd'),
                                    ('z_asgard', 'asgardmenu_metadata', 'vue', 'public', 'r'),
                                    ('z_asgard', 'asgardmanager_metadata', 'vue', 'public', 'r'),
                                    ('z_asgard', 'gestion_schema_read_only', 'vue', 'public', 'r')
                                ) AS t (a_schema, a_objet, a_type, role, droits)
                            WHERE a_schema = item.nom_schema AND a_objet = objet.objname::text AND a_type = catalogue.lib_obj ;
                    
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
                        AND NOT item.nom_schema = ANY(ARRAY['z_asgard', 'z_asgard_admin'])
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
END
$_$ ;

ALTER FUNCTION z_asgard_admin.asgard_diagnostic(text[])
    OWNER TO g_admin ;

COMMENT ON FUNCTION z_asgard_admin.asgard_diagnostic(text[]) IS 'ASGARD. Pour tous les schémas actifs référencés par Asgard, liste les écarts entre les droits effectifs et les droits standards.' ;

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
    AS $BODY$
/* Fonction exécutée par le déclencheur asgard_on_modify_gestion_schema_before
sur z_asgard_admin.gestion_schema, qui valide et normalise les informations
saisies dans la table de gestion avant leur enregistrement.

*/
DECLARE
    n_role text ;
BEGIN
    
    ------ INSERT PAR UN UTILISATEUR NON HABILITE ------
    IF TG_OP = 'INSERT' AND NOT has_database_privilege(current_database(), 'CREATE')
    -- même si creation vaut faux, seul un rôle habilité à créer des
    -- schéma peut ajouter des lignes dans la table de gestion
    THEN
        RAISE EXCEPTION 'TB1. Vous devez être habilité à créer des schémas pour réaliser cette opération.' ;
    END IF ;
    
    ------ APPLICATION DES VALEURS PAR DEFAUT ------
    -- au tout début car de nombreux tests sont faits par la
    -- suite sur "NOT NEW.creation"
    IF TG_OP IN ('INSERT', 'UPDATE')
    THEN
        NEW.creation := coalesce(NEW.creation, False) ;
        NEW.nomenclature := coalesce(NEW.nomenclature, False) ;
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
                USING HINT = 'Pour déréférencer un schéma sans le supprimer, vous pouvez utiliser la fonction z_asgard_admin.asgard_sortie_gestion_schema.' ;
        END IF;
        
        -- on n'autorise pas l'effacement pour les schémas de la nomenclature
        IF OLD.nomenclature
        THEN
            IF OLD.ctrl[1] = 'EXIT'
            THEN
                RAISE EXCEPTION 'TB26. Opération interdite (schéma %). Le déréférencement n''est pas autorisé pour les schémas de la nomenclature nationale.', OLD.nom_schema
                    USING HINT = 'Si vous tenez à déréférencer ce schéma, basculez préalablement nomenclature sur False.' ;
            ELSE
                RAISE EXCEPTION 'TB3. Opération interdite (schéma %). L''effacement n''est pas autorisé pour les schémas de la nomenclature nationale.', OLD.nom_schema
                    USING HINT = 'Si vous tenez à supprimer de la table de gestion les informations relatives à ce schéma, basculez préalablement nomenclature sur False.' ;
            END IF ;
        END IF ;
    END IF;

    ------ DE-CREATION D'UN SCHEMA ------
    IF TG_OP = 'UPDATE'
    THEN
        -- si bloc valait déjà d (schéma "mis à la corbeille")
        -- on exécute une commande de suppression du schéma. Toute autre modification sur
        -- la ligne est ignorée.
        IF OLD.bloc = 'd' AND OLD.creation AND NOT NEW.creation AND NEW.ctrl[2] IS NULL
                AND OLD.nom_schema IN (SELECT nspname FROM pg_catalog.pg_namespace)
        THEN
            -- on bloque tout de même les tentatives de suppression
            -- par un utilisateur qui n'aurait pas des droits suffisants (a priori
            -- uniquement dans le cas de g_admin avec un schéma appartenant à un
            -- super-utilisateur).
            -- c'est oid_producteur et pas producteur qui est utilisé au cas
            -- où le nom du rôle aurait été modifié entre temps
            IF NOT pg_has_role(OLD.oid_producteur, 'USAGE')
            THEN
                RAISE EXCEPTION 'TB23. Opération interdite (schéma %).', OLD.nom_schema
                    USING DETAIL = format('Seuls les membres du rôle producteur %s peuvent supprimer ce schéma.', OLD.oid_producteur::regrole) ;
            ELSE
                EXECUTE format('DROP SCHEMA %I CASCADE', OLD.nom_schema) ;
                RAISE NOTICE '... Le schéma % a été supprimé.', OLD.nom_schema ;
                RETURN NULL ;
            END IF ;
        -- sinon, on n'autorise creation à passer de true à false que si le schéma
        -- n'existe plus (permet notamment à l'event trigger qui gère les
        -- suppressions de mettre creation à false)
        ELSIF OLD.creation and NOT NEW.creation
                AND NEW.nom_schema IN (SELECT nspname FROM pg_catalog.pg_namespace)
        THEN
            RAISE EXCEPTION 'TB4. Opération interdite (schéma %). Le champ creation ne peut passer de True à False si le schéma existe.', NEW.nom_schema
                USING HINT =  'Si vous supprimez physiquement le schéma avec la commande DROP SCHEMA, creation basculera sur False automatiquement.' ;
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
                    USING DETAIL = 'Seuls les membres de g_admin sont habilités à modifier les champs nomenclature et - pour les schémas de la nomenclature - bloc, niv1, niv1_abr, niv2, niv2_abr et nom_schema.' ;
            END IF ;
        ELSIF TG_OP = 'INSERT'
        THEN
            IF NEW.nomenclature AND NOT pg_has_role('g_admin', 'MEMBER')
            THEN
                RAISE EXCEPTION 'TB19. Opération interdite (schéma %).', NEW.nom_schema
                    USING DETAIL = 'Seuls les membres de g_admin sont autorisés à ajouter des schémas à la nomenclature (nomenclature = True).' ;
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
            RAISE EXCEPTION 'TB8. Saisie incorrecte. Le nom du schéma doit être renseigné (champ nom_schema).' ;
        END IF ;
        
        -- unicité de nom_schema
        -- -> contrôlé après les manipulations sur les blocs de
        -- la partie suivante.
        
        -- unicité de oid_schema
        IF TG_OP = 'INSERT' AND NEW.oid_schema IN (SELECT gestion_schema_etr.oid_schema FROM z_asgard.gestion_schema_etr
                                                       WHERE gestion_schema_etr.oid_schema IS NOT NULL)
        THEN
            RAISE EXCEPTION 'TB11. Saisie incorrecte (schéma %). Un schéma de même OID est déjà répertorié dans la table de gestion.', NEW.nom_schema ;
        ELSIF TG_OP = 'UPDATE'
        THEN
            -- cas (très hypothétique) d'une modification d'OID
            IF NOT coalesce(NEW.oid_schema, -1) = coalesce(OLD.oid_schema, -1)
                    AND NEW.oid_schema IN (SELECT gestion_schema_etr.oid_schema FROM z_asgard.gestion_schema_etr
                                                       WHERE gestion_schema_etr.oid_schema IS NOT NULL)
            THEN
                RAISE EXCEPTION 'TB12. Saisie incorrecte (schéma %). Un schéma de même OID est déjà répertorié dans la table de gestion.', NEW.nom_schema ;
            END IF ;
        END IF ;
        
        -- non répétition des rôles
        IF NOT ((NEW.oid_lecteur IS NULL OR NOT NEW.oid_lecteur = NEW.oid_producteur)
                AND (NEW.oid_editeur IS NULL OR NOT NEW.oid_editeur = NEW.oid_producteur)
                AND (NEW.oid_lecteur IS NULL OR NEW.oid_editeur IS NULL OR NOT NEW.oid_lecteur = NEW.oid_editeur))
        THEN
            RAISE EXCEPTION 'TB13. Saisie incorrecte (schéma %). Les rôles producteur, lecteur et éditeur doivent être distincts.', NEW.nom_schema ;
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
                        RAISE EXCEPTION 'TB14. Saisie invalide (schéma %). Le bloc doit être une lettre minuscule ou rien.', NEW.nom_schema ;
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
                    RAISE EXCEPTION 'TB15. Saisie invalide (schéma %). Le bloc doit être une lettre minuscule ou rien.', NEW.nom_schema ;
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
                RAISE EXCEPTION 'TB16. Saisie invalide (schéma %). Le bloc doit être une lettre minuscule ou rien.', NEW.nom_schema ;
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
        IF TG_OP = 'INSERT' AND NEW.nom_schema IN (SELECT gestion_schema_etr.nom_schema FROM z_asgard.gestion_schema_etr)
        THEN
            RAISE EXCEPTION 'TB9. Saisie incorrecte (schéma %). Un schéma de même nom est déjà répertorié dans la table de gestion.', NEW.nom_schema ;
        ELSIF TG_OP = 'UPDATE'
        THEN
            -- cas d'un changement de nom
            IF NOT NEW.nom_schema = OLD.nom_schema
                   AND NEW.nom_schema IN (SELECT gestion_schema_etr.nom_schema FROM z_asgard.gestion_schema_etr)
            THEN 
                RAISE EXCEPTION 'TB10. Saisie incorrecte (schéma %). Un schéma de même nom est déjà répertorié dans la table de gestion.', NEW.nom_schema ;
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
    
    ------ SCHEMAS DES SUPER-UTILISATEURS ------
    -- concerne uniquement les membres de g_admin, qui voient tous
    -- les schémas, y compris ceux des super-utilisateurs dont ils
    -- ne sont pas membres. Les contrôles suivants bloquent dans ce
    -- cas les tentatives de mise à jour des champs nom_schema,
    -- producteur, editeur et lecteur, ainsi que les création de schéma
    -- via un INSERT ou un UPDATE.
    IF TG_OP = 'UPDATE'
    THEN
        IF OLD.creation
            AND OLD.producteur IN (SELECT rolname FROM pg_catalog.pg_roles WHERE rolsuper)
            AND (
                NOT OLD.nom_schema = NEW.nom_schema
                OR NOT OLD.producteur = NEW.producteur AND (NEW.ctrl IS NULL OR NOT 'CLEAN producteur' = ANY(array_remove(NEW.ctrl, NULL)))
                OR NOT coalesce(OLD.editeur, '') = coalesce(NEW.editeur, '') AND (NEW.ctrl IS NULL OR NOT 'CLEAN editeur' = ANY(array_remove(NEW.ctrl, NULL)))
                OR NOT coalesce(OLD.lecteur, '') = coalesce(NEW.lecteur, '') AND (NEW.ctrl IS NULL OR NOT 'CLEAN lecteur' = ANY(array_remove(NEW.ctrl, NULL)))
                )
        THEN
            IF NOT pg_has_role(OLD.producteur, 'USAGE')
            THEN
                RAISE EXCEPTION 'TB20. Opération interdite (schéma %).', OLD.nom_schema
                    USING DETAIL = format('Seul le rôle producteur %s (super-utilisateur) peut modifier ce schéma.', OLD.producteur) ;
            END IF ;
        END IF ;
        
        IF NEW.creation
            AND NOT OLD.creation
            AND NEW.producteur IN (SELECT rolname FROM pg_catalog.pg_roles WHERE rolsuper)
        THEN
            IF NOT pg_has_role(NEW.producteur, 'USAGE')
            THEN
                RAISE EXCEPTION 'TB21. Opération interdite (schéma %).', NEW.nom_schema
                    USING DETAIL = format('Seul le super-utilisateur %s peut créer un schéma dont il est identifié comme producteur.', NEW.producteur) ;
            END IF ;
        END IF ;
        
        IF NEW.producteur IN (SELECT rolname FROM pg_catalog.pg_roles WHERE rolsuper)
            AND NEW.creation
            AND NOT OLD.producteur = NEW.producteur AND (NEW.ctrl IS NULL OR NOT 'CLEAN producteur' = ANY(array_remove(NEW.ctrl, NULL)))
        THEN
            IF NOT pg_has_role(NEW.producteur, 'USAGE')
            THEN
                RAISE EXCEPTION 'TB24. Opération interdite (schéma %).', NEW.nom_schema
                    USING DETAIL = format('Seul le super-utilisateur %s peut se désigner comme producteur d''un schéma.', NEW.producteur) ;
            END IF ;
        END IF ;
        
    ELSIF TG_OP = 'INSERT'
    THEN
        IF NEW.producteur IN (SELECT rolname FROM pg_catalog.pg_roles WHERE rolsuper)
            AND NEW.creation
            AND NOT NEW.nom_schema IN (SELECT nspname FROM pg_catalog.pg_namespace)
            -- on exclut les schémas en cours de référencement, qui sont gérés
            -- juste après, avec leur propre message d'erreur
        THEN
            IF NOT pg_has_role(NEW.producteur, 'USAGE')                
            THEN
                RAISE EXCEPTION 'TB22. Opération interdite (schéma %).', NEW.nom_schema
                    USING DETAIL = format('Seul le super-utilisateur %s peut créer un schéma dont il est identifié comme producteur.', NEW.producteur) ;
            END IF ;
        END IF ;            
        
        IF NEW.producteur IN (SELECT rolname FROM pg_catalog.pg_roles WHERE rolsuper)
                AND NEW.nom_schema IN (SELECT nspname FROM pg_catalog.pg_namespace)
                -- schéma pré-existant en cours de référencement
        THEN
            IF NOT pg_has_role(NEW.producteur, 'USAGE') 
            THEN
                RAISE EXCEPTION 'TB25. Opération interdite (schéma %).', NEW.nom_schema
                    USING DETAIL = format('Seul le super-utilisateur %s peut référencer dans ASGARD un schéma dont il est identifié comme producteur.', NEW.producteur) ;
            END IF ;
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
    
END
$BODY$ ;

ALTER FUNCTION z_asgard_admin.asgard_on_modify_gestion_schema_before()
    OWNER TO g_admin ;

COMMENT ON FUNCTION z_asgard_admin.asgard_on_modify_gestion_schema_before() IS 'ASGARD. Fonction exécutée par le déclencheur asgard_on_modify_gestion_schema_before sur z_asgard_admin.gestion_schema, qui valide et normalise les informations saisies dans la table de gestion avant leur enregistrement.' ;


-- Trigger: asgard_on_modify_gestion_schema_before
    
COMMENT ON TRIGGER asgard_on_modify_gestion_schema_before ON z_asgard_admin.gestion_schema IS 'ASGARD. Déclencheur qui valide et normalise les informations saisies dans la table de gestion avant leur enregistrement.' ;


------ 5.2 - TRIGGER AFTER ------

-- Function: z_asgard_admin.asgard_on_modify_gestion_schema_after()

CREATE OR REPLACE FUNCTION z_asgard_admin.asgard_on_modify_gestion_schema_after()
    RETURNS trigger
    LANGUAGE plpgsql
    AS $BODY$
/* Fonction exécutée par le déclencheur asgard_on_modify_gestion_schema_after
sur z_asgard_admin.gestion_schema, qui répercute physiquement les modifications
de la table de gestion.

*/
DECLARE
    utilisateur text ;
    createur text ;
    administrateur text ;
    e_mssg text ;
    e_hint text ;
    e_detl text ;
    b_superuser boolean ;
    b_test boolean ;
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
    utilisateur := current_user ;
    
    -- si besoin pour les futures opérations sur les rôles,
    -- récupération du nom d'un rôle dont current_user est membre
    -- et qui a l'attribut CREATEROLE. Autant que possible, la
    -- requête renvoie current_user lui-même. On exclut d'office les
    -- rôles NOINHERIT qui ne pourront pas avoir simultanément les
    -- droits du propriétaire de NEW et OLD.producteur
    SELECT rolname INTO createur FROM pg_roles
        WHERE pg_has_role(rolname, 'MEMBER') AND rolcreaterole AND rolinherit
        ORDER BY rolname = current_user DESC ;
    
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
        IF NOT FOUND AND OLD.creation AND (NEW.ctrl IS NULL OR NOT 'CLEAN producteur' = ANY(array_remove(NEW.ctrl, NULL)))
        THEN
            RAISE NOTICE '[table de gestion] ANOMALIE. Schéma %. L''OID actuellement renseigné pour le producteur dans la table de gestion est invalide. Poursuite avec l''OID du propriétaire courant du schéma.', OLD.nom_schema ;
            SELECT rolname INTO a_producteur
                FROM pg_catalog.pg_namespace
                    LEFT JOIN pg_catalog.pg_roles ON pg_roles.oid = nspowner
                WHERE pg_namespace.oid = NEW.oid_schema ;
            IF NOT FOUND
            THEN
                RAISE EXCEPTION 'TA1. Anomalie critique (schéma %). Le propriétaire du schéma est introuvable.', OLD.nom_schema ;
            END IF ;
        END IF ;
    END IF ;

    ------ MISE EN APPLICATION D'UN CHANGEMENT DE NOM DE SCHEMA ------
    IF NOT NEW.oid_schema::regnamespace::text = quote_ident(NEW.nom_schema)
    -- le schéma existe et ne porte pas déjà le nom NEW.nom_schema
    THEN
        EXECUTE format('ALTER SCHEMA %s RENAME TO %I', NEW.oid_schema::regnamespace, NEW.nom_schema) ;
        RAISE NOTICE '... Le schéma % a été renommé.', NEW.nom_schema ;
    END IF ; 
    -- exclusion des remontées d'event trigger correspondant
    -- à des changements de noms
    IF NEW.ctrl[1] = 'RENAME'
    THEN
        -- on signale la fin du traitement, ce qui
        -- va notamment permettre l'exécution de
        -- asgard_visibilite_admin_after
        UPDATE z_asgard.gestion_schema_etr
            SET ctrl = ARRAY['END', 'x7-A;#rzo']
            WHERE nom_schema = NEW.nom_schema ;
        
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
    b_test := False ;
    IF NOT NEW.creation
    THEN
        b_test := True ;
    ELSIF TG_OP = 'UPDATE'
    THEN
        IF OLD.creation
                AND (NEW.producteur = OLD.producteur  OR 'CLEAN producteur' = ANY(array_remove(NEW.ctrl, NULL)))
                AND (coalesce(NEW.editeur, '') = coalesce(OLD.editeur, '') OR 'CLEAN editeur' = ANY(array_remove(NEW.ctrl, NULL)))
                AND (coalesce(NEW.lecteur, '') = coalesce(OLD.lecteur, '') OR 'CLEAN lecteur' = ANY(array_remove(NEW.ctrl, NULL)))
        THEN
            b_test := True ;
        END IF ;
    END IF ;
    
    IF NOT b_test
    THEN
        IF NOT NEW.producteur IN (SELECT rolname FROM pg_catalog.pg_roles)
        -- si le producteur désigné n'existe pas, on le crée
        -- ou renvoie une erreur si les privilèges de l'utilisateur
        -- sont insuffisants
        THEN
            IF createur IS NULL
            THEN
                RAISE EXCEPTION 'TA2. Opération interdite. Vous n''êtes pas habilité à créer le rôle %.', NEW.producteur
                    USING HINT = 'Être membre d''un rôle disposant des attributs CREATEROLE et INHERIT est nécessaire pour créer de nouveaux producteurs.' ;
            END IF ;
            EXECUTE format('SET ROLE %I', createur) ;
            EXECUTE format('CREATE ROLE %I', NEW.producteur) ;
            RAISE NOTICE '... Le rôle de groupe % a été créé.', NEW.producteur ;
            EXECUTE format('SET ROLE %I', utilisateur) ;                
        ELSE
        -- si le rôle producteur existe, on vérifie qu'il n'a pas l'option LOGIN
        -- les superusers avec LOGIN (comme postgres) sont tolérés
        -- paradoxe ou non, dans l'état actuel des choses, cette erreur se
        -- déclenche aussi lorsque la modification ne porte que sur les rôles
        -- lecteur/éditeur
            SELECT rolsuper INTO b_superuser
                FROM pg_roles WHERE rolname = NEW.producteur AND rolcanlogin ;
            IF NOT b_superuser
            THEN
                RAISE EXCEPTION 'TA3. Opération interdite (schéma %). Le producteur/propriétaire du schéma ne doit pas être un rôle de connexion.', NEW.nom_schema ;
            END IF ;
        END IF ;
        b_superuser := coalesce(b_superuser, False) ;
        
        -- mise à jour du champ d'OID du producteur
        IF NEW.ctrl[1] IS NULL OR NOT NEW.ctrl[1] IN ('OWNER', 'CREATE')
        -- pas dans le cas d'une remontée de commande directe
        -- où l'OID du producteur sera déjà renseigné
        -- et uniquement s'il a réellement été modifié (ce
        -- qui n'est pas le cas si les changements ne portent
        -- que sur les rôles lecteur/éditeur)
        THEN
            UPDATE z_asgard.gestion_schema_etr
                SET oid_producteur = quote_ident(NEW.producteur)::regrole::oid,
                    ctrl = ARRAY['SELF', 'x7-A;#rzo']
                WHERE nom_schema = NEW.nom_schema AND (
                    oid_producteur IS NULL
                    OR NOT oid_producteur = quote_ident(NEW.producteur)::regrole::oid
                    ) ;
        END IF ;

        -- implémentation des permissions manquantes sur NEW.producteur
        IF NOT pg_has_role(utilisateur, NEW.producteur, 'USAGE')
        THEN
            b_test := True ;
            IF createur IS NULL OR b_superuser
            THEN
                RAISE EXCEPTION 'TA4. Opération interdite. Permissions insuffisantes pour le rôle %.', NEW.producteur
                    USING HINT = format('Votre rôle doit être membre de %s ou disposer de l''attribut CREATEROLE pour réaliser cette opération.',
                        NEW.producteur) ;
            END IF ;
        END IF ;
        IF TG_OP = 'UPDATE'
        THEN
            IF OLD.creation AND NOT pg_has_role(utilisateur, a_producteur, 'USAGE')
                AND NOT (NEW.producteur = OLD.producteur  OR 'CLEAN producteur' = ANY(array_remove(NEW.ctrl, NULL)))
                -- les permissions sur OLD.producteur ne sont contrôlées que si le producteur
                -- a effectivement été modifié
            THEN
                b_test := True ;
                IF createur IS NULL OR b_superuser
                THEN
                    RAISE EXCEPTION 'TA5. Opération interdite. Permissions insuffisantes pour le rôle %.', a_producteur
                        USING HINT = format('Votre rôle doit être membre de %s ou disposer de l''attribut CREATEROLE pour réaliser cette opération.',
                            a_producteur) ;
                END IF ;            
            END IF ;
        END IF ;       
        IF b_test
        THEN
            EXECUTE format('SET ROLE %I', createur) ;            
            -- par commodité, on rend createur membre à la fois de NEW et (si besoin)
            -- de OLD.producteur, même si l'utilisateur avait déjà accès à
            -- l'un des deux par ailleurs :
            IF NOT pg_has_role(createur, NEW.producteur, 'USAGE') AND NOT b_superuser
            THEN
                EXECUTE format('GRANT %I TO %I', NEW.producteur, createur) ;
                RAISE NOTICE USING MESSAGE = format('... Permission accordée à %s sur le rôle %s.', createur, NEW.producteur) ;
            END IF ;
            IF TG_OP = 'UPDATE'
            THEN
                IF NOT pg_has_role(createur, a_producteur, 'USAGE') AND NOT b_superuser
                THEN
                    EXECUTE format('GRANT %I TO %I', a_producteur, createur) ;
                    RAISE NOTICE USING MESSAGE = format('... Permission accordée à %s sur le rôle %s.', createur, a_producteur) ;
                END IF ;
            END IF ;
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
    b_test := False ;
    IF NOT NEW.creation OR NEW.editeur IS NULL
            OR 'CLEAN editeur' = ANY(array_remove(NEW.ctrl, NULL))
    THEN
        b_test := True ;
    ELSIF TG_OP = 'UPDATE'
    THEN
        IF OLD.creation AND NEW.editeur = OLD.editeur
        THEN
            b_test := True ;           
        END IF ;
    END IF ;
    
    IF NOT b_test
    THEN
        IF NOT NEW.editeur IN (SELECT rolname FROM pg_catalog.pg_roles)
                AND NOT NEW.editeur = 'public'
        -- si l'éditeur désigné n'existe pas, on le crée
        -- ou renvoie une erreur si les privilèges de l'utilisateur
        -- sont insuffisants
        THEN
            IF createur IS NULL
            THEN
                RAISE EXCEPTION 'TA7. Opération interdite. Vous n''êtes pas habilité à créer le rôle %.', NEW.editeur
                    USING HINT = 'Être membre d''un rôle disposant des attributs CREATEROLE et INHERIT est nécessaire pour créer de nouveaux éditeurs.' ;
            END IF ;
            EXECUTE format('SET ROLE %I', createur) ;
            EXECUTE format('CREATE ROLE %I', NEW.editeur) ;
            RAISE NOTICE '... Le rôle de groupe % a été créé.', NEW.editeur ;
            EXECUTE format('SET ROLE %I', utilisateur) ;
        END IF ;
        
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
    b_test := False ;
    IF NOT NEW.creation OR NEW.lecteur IS NULL
            OR 'CLEAN lecteur' = ANY(array_remove(NEW.ctrl, NULL))
    THEN
        b_test := True ;
    ELSIF TG_OP = 'UPDATE'
    THEN
        IF OLD.creation AND NEW.lecteur = OLD.lecteur
        THEN
            b_test := True ;
        END IF ;
    END IF ;
    
    IF NOT b_test
    THEN
        IF NOT NEW.lecteur IN (SELECT rolname FROM pg_catalog.pg_roles)
                AND NOT NEW.lecteur = 'public'
        -- si le lecteur désigné n'existe pas, on le crée
        -- ou renvoie une erreur si les privilèges de l'utilisateur
        -- sont insuffisants
        THEN
            IF createur IS NULL
            THEN
                RAISE EXCEPTION 'TA8. Opération interdite. Vous n''êtes pas habilité à créer le rôle %.', NEW.lecteur
                    USING HINT = 'Être membre d''un rôle disposant des attributs CREATEROLE et INHERIT est nécessaire pour créer de nouveaux éditeurs.' ;
            END IF ;
            EXECUTE format('SET ROLE %I', createur) ;
            EXECUTE format('CREATE ROLE %I', NEW.lecteur) ;
            RAISE NOTICE '... Le rôle de groupe % a été créé.', NEW.lecteur ;
            EXECUTE format('SET ROLE %I', utilisateur) ;
        END IF ;
        
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
    END IF ;
    
    ------ CREATION DU SCHEMA ------
    -- on exclut au préalable les cas qui ne
    -- correspondent pas à des créations, ainsi que les
    -- remontées de l'event trigger sur CREATE SCHEMA,
    -- car le schéma existe alors déjà
    b_test := False ;
    IF NOT NEW.creation OR NEW.ctrl[1] = 'CREATE'
    THEN
        b_test := True ;
    ELSIF TG_OP = 'UPDATE'
    THEN
        IF OLD.creation
        THEN
            b_test := True ;
        END IF ;
    END IF ;
    
    IF NOT b_test
    THEN
        -- le schéma est créé s'il n'existe pas déjà (cas d'ajout
        -- d'un schéma pré-existant qui n'était pas référencé dans
        -- gestion_schema jusque-là), sinon on alerte juste
        -- l'utilisateur
        IF NOT NEW.nom_schema IN (SELECT nspname FROM pg_catalog.pg_namespace)
        THEN
            IF NOT has_database_privilege(current_database(), 'CREATE')
                    OR NOT pg_has_role(NEW.producteur, 'USAGE')
            THEN
                -- si le rôle courant n'a pas les privilèges nécessaires pour
                -- créer le schéma, on tente avec le rôle createur [de rôles]
                -- pré-identifié, dont on sait au moins qu'il aura les
                -- permissions nécessaires sur le rôle producteur - mais pas
                -- s'il est habilité à créer des schémas
                IF createur IS NOT NULL
                THEN
                    EXECUTE format('SET ROLE %I', createur) ;
                END IF ;
                IF NOT has_database_privilege(current_database(), 'CREATE')
                        OR NOT pg_has_role(NEW.producteur, 'USAGE')
                THEN
                    RAISE EXCEPTION 'TA9. Opération interdite. Vous n''êtes pas habilité à créer le schéma %.', NEW.nom_schema
                        USING HINT = 'Être membre d''un rôle disposant du privilège CREATE sur la base de données est nécessaire pour créer des schémas.' ;
                END IF ;
            END IF ;
            EXECUTE format('CREATE SCHEMA %I AUTHORIZATION %I', NEW.nom_schema, NEW.producteur) ;
            EXECUTE format('SET ROLE %I', utilisateur) ;
            RAISE NOTICE '... Le schéma % a été créé.', NEW.nom_schema ;
        ELSE
            RAISE NOTICE '(schéma % pré-existant)', NEW.nom_schema ;
        END IF ;
        -- récupération de l'OID du schéma
        UPDATE z_asgard.gestion_schema_etr
            SET oid_schema = quote_ident(NEW.nom_schema)::regnamespace::oid,
                ctrl = ARRAY['SELF', 'x7-A;#rzo']
            WHERE nom_schema = NEW.nom_schema AND (
                oid_schema IS NULL
                OR NOT oid_schema = quote_ident(NEW.nom_schema)::regnamespace::oid
                ) ;   
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
    b_test := False ;
    IF NOT NEW.creation
            OR 'CLEAN producteur' = ANY(array_remove(NEW.ctrl, NULL))
            OR NEW.ctrl[1] = 'CREATE'
            OR NEW.nom_schema = 'z_asgard_admin'
    THEN
        b_test := True ;
    ELSIF TG_OP = 'UPDATE'
    THEN
        IF OLD.creation AND NEW.producteur = OLD.producteur
        THEN
            b_test := True ;
        END IF ;
    END IF ;
    
    IF NOT b_test
    THEN
        -- si besoin, on bascule sur le rôle createur. À ce stade,
        -- il est garanti que soit l'utilisateur courant soit
        -- createur (pour le cas d'un utilisateur courant
        -- NOINHERIT) aura les privilèges nécessaires
        IF NOT pg_has_role(NEW.producteur, 'USAGE')
        THEN
            EXECUTE format('SET ROLE %I', createur) ;
        ELSIF TG_OP = 'UPDATE'
        THEN
            IF NOT pg_has_role(a_producteur, 'USAGE')
            THEN
                EXECUTE format('SET ROLE %I', createur) ; 
            END IF ;
        END IF ;
        
        -- changements de propriétaires
        IF (NEW.nom_schema, NEW.producteur)
                IN (SELECT schema_name, schema_owner FROM information_schema.schemata)
        THEN
            -- si producteur est déjà propriétaire du schéma (cas d'une remontée de l'event trigger,
            -- principalement), on ne change que les propriétaires des objets éventuels
            IF quote_ident(NEW.nom_schema)::regnamespace::oid
                    IN (SELECT refobjid FROM pg_catalog.pg_depend WHERE deptype = 'n')
            THEN 
                -- la commande n'est cependant lancée que s'il existe des dépendances de type
                -- DEPENDENCY_NORMAL sur le schéma, ce qui est une condition nécessaire à
                -- l'existence d'objets dans le schéma
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
            RAISE NOTICE 'attribution de la propriété du schéma et des objets au rôle producteur du schéma % :', NEW.nom_schema ;
            PERFORM z_asgard.asgard_admin_proprietaire(NEW.nom_schema, NEW.producteur) ;
        END IF ;
        
        EXECUTE format('SET ROLE %I', utilisateur) ;
    END IF ;
    
    ------ APPLICATION DES DROITS DE L'EDITEUR ------
    -- on ne s'intéresse pas aux cas :
    -- - d'un schéma qui n'a pas/plus vocation à exister ;
    -- - d'un schéma pré-existant dont l'éditeur ne change pas
    --   (y compris pour rester vide) ou dont le libellé
    --   a seulement été nettoyé par le trigger BEFORE.
    -- ils sont donc exclus au préalable
    b_test := False ;
    IF NOT NEW.creation OR 'CLEAN editeur' = ANY(array_remove(NEW.ctrl, NULL))
    THEN
        b_test := True ;
    ELSIF TG_OP = 'UPDATE'
    THEN
        IF OLD.creation
            AND coalesce(NEW.editeur, '') = coalesce(OLD.editeur, '')
        THEN
            b_test := True ;           
        END IF ;
    END IF ;
    
    IF NOT b_test
    THEN
        -- si besoin, on bascule sur le rôle createur. À ce stade,
        -- il est garanti que soit l'utilisateur courant soit
        -- createur (pour le cas d'un utilisateur courant
        -- NOINHERIT) aura les privilèges nécessaires
        IF NOT pg_has_role(NEW.producteur, 'USAGE')
        THEN
            EXECUTE format('SET ROLE %I', createur) ;
        END IF ;
        
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
    b_test := False ;
    l_commande := NULL ;
    IF NOT NEW.creation OR 'CLEAN lecteur' = ANY(array_remove(NEW.ctrl, NULL))
    THEN
        b_test := True ;
    ELSIF TG_OP = 'UPDATE'
    THEN
        IF OLD.creation
            AND coalesce(NEW.lecteur, '') = coalesce(OLD.lecteur, '')
        THEN
            b_test := True ;           
        END IF ;
    END IF ;
    
    IF NOT b_test
    THEN
        -- si besoin, on bascule sur le rôle createur. À ce stade,
        -- il est garanti que soit l'utilisateur courant soit
        -- createur (pour le cas d'un utilisateur courant
        -- NOINHERIT) aura les privilèges nécessaires
        IF NOT pg_has_role(NEW.producteur, 'USAGE')
        THEN
            EXECUTE format('SET ROLE %I', createur) ;
        END IF ;
        
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

    -- on signale la fin du traitement, ce qui
    -- va notamment permettre l'exécution de
    -- asgard_visibilite_admin_after
    UPDATE z_asgard.gestion_schema_etr
        SET ctrl = ARRAY['END', 'x7-A;#rzo']
        WHERE nom_schema = NEW.nom_schema
            AND (ctrl[1] IS NULL OR NOT ctrl[1] = 'EXIT') ;
    
	RETURN NULL ;

EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                            e_hint = PG_EXCEPTION_HINT,
                            e_detl = PG_EXCEPTION_DETAIL ;
    RAISE EXCEPTION 'TA0 > %', e_mssg
        USING DETAIL = e_detl,
            HINT = e_hint ;
               
END
$BODY$ ;

ALTER FUNCTION z_asgard_admin.asgard_on_modify_gestion_schema_after()
    OWNER TO g_admin ;

COMMENT ON FUNCTION z_asgard_admin.asgard_on_modify_gestion_schema_after() IS 'ASGARD. Fonction exécutée par le déclencheur asgard_on_modify_gestion_schema_after sur z_asgard_admin.gestion_schema, qui répercute physiquement les modifications de la table de gestion.' ;


-- Trigger: asgard_on_modify_gestion_schema_after

COMMENT ON TRIGGER asgard_on_modify_gestion_schema_after ON z_asgard_admin.gestion_schema IS 'ASGARD. Déclencheur qui répercute physiquement les modifications de la table de gestion.' ;


------ 5.3 - TRIGGER DE GESTION DES PERMISSIONS DE G_ADMIN ------

-- Function: z_asgard_admin.asgard_visibilite_admin_after()

CREATE OR REPLACE FUNCTION z_asgard_admin.asgard_visibilite_admin_after()
    RETURNS trigger
    LANGUAGE plpgsql
    SECURITY DEFINER
    AS $BODY$
/* Fonction exécutée par le déclencheur asgard_visibilite_admin_after sur
z_asgard_admin.gestion_schema, qui assure que g_admin soit toujours membre
des rôles producteurs des schémas référencés, hors super-utilisateurs.

    Notes
    -----
    Il s'agit d'une fonction SECURITY DEFINER, qui s'exécute avec les
    droits de g_admin, profitant notamment de son attribut CREATEROLE.

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
    invalid_grant_operation
        TVA2. Lorsque le rôle producteur du schéma auquel se rapporte
        l'enregistrement en cours d'édition est membre de g_admin, directement
        ou non (permissions circulaires).

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

    ------- GESTION DES PERMISSIONS DE G_ADMIN ------

    -- on écarte les schémas non actifs et le cas où le
    -- producteur est g_admin
    IF NOT NEW.creation OR NEW.producteur = 'g_admin'
    THEN
        RETURN NULL ;
    END IF ;

    -- pas de contrôle sur le fait que le producteur a changé, car il n'est
    -- pas plus mal de confirmer les permissions de g_admin, au cas où elles
    -- auraient été supprimées entre temps, ce qui ne sera jamais une bonne
    -- chose

    -- on ne considère pas le cas où le producteur est un super-utilisateur
    IF NEW.producteur IN (SELECT rolname FROM pg_catalog.pg_roles WHERE rolsuper)
    THEN
        RETURN NULL ;
    END IF ;

    -- ni le cas où g_admin est déjà directement membre du producteur
    IF 'g_admin'::regrole IN (
            SELECT member FROM pg_catalog.pg_auth_members
                WHERE roleid = quote_ident(NEW.producteur)::regrole
            )
        -- NB: on n'utilise pas NEW.oid_producteur, car c'est 
        -- asgard_on_modify_gestion_schema_after qui arrête définitivement
        -- sa valeur.
    THEN
        RETURN NULL ;
    END IF ;
    
    -- si le producteur est membres de g_admin, on retourne une erreur
    IF pg_has_role(NEW.producteur, 'g_admin', 'MEMBER')
    THEN
        RAISE EXCEPTION 'TVA2. Opération interdite. Les rôles producteurs/propriétaires de schémas non super-utilisateurs ne peuvent pas être membres de g_admin, y compris par héritage.'
            USING HINT = format('Pourquoi ne pas désigner directement de g_admin comme producteur du schéma %I ?', NEW.nom_schema),
                SCHEMA = NEW.nom_schema,
                ERRCODE = 'invalid_grant_operation' ;
    END IF ;

    EXECUTE format('GRANT %I TO g_admin', NEW.producteur) ;
    RAISE NOTICE '... Permission accordée à g_admin sur le rôle %.', NEW.producteur ;

    RETURN NULL ;
    
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                            e_hint = PG_EXCEPTION_HINT,
                            e_detl = PG_EXCEPTION_DETAIL,
                            e_errcode = RETURNED_SQLSTATE,
                            e_schema = SCHEMA_NAME ;
    RAISE EXCEPTION 'TVA0 > %', e_mssg
        USING DETAIL = e_detl,
            HINT = e_hint,
            SCHEMA = e_schema,
            ERRCODE = e_errcode ;
               
END
$BODY$ ;

ALTER FUNCTION z_asgard_admin.asgard_visibilite_admin_after()
    OWNER TO g_admin ;
    
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


-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


