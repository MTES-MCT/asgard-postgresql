\echo Use "CREATE EXTENSION asgard" to load this file. \quit
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
--
-- ASGARD - Système de gestion des droits pour PostgreSQL, version 1.3.2
-- > Script de mise à jour depuis la version 1.3.1.
--
-- Copyright République Française, 2020-2022.
-- Secrétariat général du Ministère de la transition écologique, du
-- Ministère de la cohésion des territoires et des relations avec les
-- collectivités territoriales et du Ministère de la Mer.
-- Service du numérique.
--
-- contributrice pour cette version : Leslie Lemaire (SNUM/UNI/DRC).
-- 
-- mél : drc.uni.snum.sg@developpement-durable.gouv.fr
--
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
--
-- Note de version :
-- https://snum.scenari-community.org/Asgard/Documentation/#SEC_1-3-2
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
-- objets modifiés par le script :
-- - Function: z_asgard_admin.asgard_on_create_schema()
-- - Event Trigger: asgard_on_create_schema
-- - Function: z_asgard_admin.asgard_on_drop_schema()
-- - Event Trigger: asgard_on_drop_schema
-- - Function: z_asgard.asgard_synthese_role(regnamespace, regrole)
-- - Function: z_asgard.asgard_synthese_public(regnamespace)
-- - Function: z_asgard.asgard_synthese_role_obj(oid, text, regrole)
-- - Function: z_asgard.asgard_synthese_public_obj(oid, text)
-- - Function: z_asgard.asgard_initialise_schema(text, boolean, boolean)
-- - Function: z_asgard_admin.asgard_reaffecte_role(text, text, boolean, boolean, boolean)
-- - Function: z_asgard.asgard_expend_privileges(text)
-- - Function: z_asgard_admin.asgard_diagnostic(text[])
--
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


--------------------------------------------
------ 3 - CREATION DES EVENT TRIGGERS ------
--------------------------------------------
/* 3.2 - EVENT TRIGGER SUR CREATE SCHEMA
   3.3 - EVENT TRIGGER SUR DROP SCHEMA */
   

------ 3.2 - EVENT TRIGGER SUR CREATE SCHEMA ------

-- Function: z_asgard_admin.asgard_on_create_schema()

CREATE OR REPLACE FUNCTION z_asgard_admin.asgard_on_create_schema() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $BODY$
/* OBJET : Fonction exécutée par l'event trigger asgard_on_create_schema qui
           répercute dans la table z_asgard_admin.gestion_schema (via la vue
           z_asgard.gestion_schema_etr) les créations de schémas
           réalisées par des commandes CREATE SCHEMA directes ou exécutées
           dans le cadre de l'installation d'une extension.
DECLENCHEMENT : ON DDL COMMAND END.
CONDITION : WHEN TAG IN ('CREATE SCHEMA', 'CREATE EXTENSION') */
DECLARE
    obj record ;
    e_mssg text ;
    e_hint text ;
    e_detl text ;
BEGIN
    ------ CONTROLES DES PRIVILEGES ------
    IF NOT has_schema_privilege('z_asgard', 'USAGE')
    THEN
        RAISE EXCEPTION 'ECS1. Vous devez être membre du groupe éditeur du schéma z_asgard pour réaliser cette opération.' ;
    END IF ;
    
    IF NOT has_table_privilege('z_asgard.gestion_schema_etr', 'UPDATE')
            OR NOT has_table_privilege('z_asgard.gestion_schema_etr', 'INSERT')
            OR NOT has_table_privilege('z_asgard.gestion_schema_etr', 'SELECT')
    THEN
        RAISE EXCEPTION 'ECS2. Vous devez être membre du groupe éditeur du schéma z_asgard pour réaliser cette opération.' ;
    END IF ;


	FOR obj IN SELECT * FROM pg_event_trigger_ddl_commands()
                    WHERE object_type = 'schema'
    LOOP
    
        ------ SCHEMA PRE-ENREGISTRE DANS GESTION_SCHEMA ------
        UPDATE z_asgard.gestion_schema_etr
            SET (oid_schema, producteur, oid_producteur, creation, ctrl) = (
                SELECT
                    obj.objid,
                    replace(nspowner::regrole::text, '"', ''),
                    nspowner,
                    true,
                    ARRAY['CREATE', 'x7-A;#rzo']
                    FROM pg_catalog.pg_namespace
                    WHERE obj.objid = pg_namespace.oid
                )
            WHERE quote_ident(nom_schema) = obj.object_identity
                AND NOT creation  ; -- creation vaut true si et seulement si la création a été initiée via la table
                                    -- de gestion dans ce cas, il n'est pas nécessaire de réintervenir dessus
        IF FOUND
        THEN
            RAISE NOTICE '... Le schéma % apparaît désormais comme "créé" dans la table de gestion.',  replace(obj.object_identity, '"', '') ;

        ------ SCHEMA NON REPERTORIE DANS GESTION_SCHEMA ------
        ELSIF NOT obj.object_identity IN (SELECT quote_ident(nom_schema) FROM z_asgard.gestion_schema_etr)
        THEN
            INSERT INTO z_asgard.gestion_schema_etr (oid_schema, nom_schema, producteur, oid_producteur, creation, ctrl)(
                SELECT
                    obj.objid,
                    replace(obj.object_identity, '"', ''),
                    replace(nspowner::regrole::text, '"', ''),
                    nspowner,
                    true,
                    ARRAY['CREATE', 'x7-A;#rzo']
                    FROM pg_catalog.pg_namespace
                    WHERE obj.objid = pg_namespace.oid
                ) ;
            RAISE NOTICE '... Le schéma % a été enregistré dans la table de gestion.',  replace(obj.object_identity, '"', '') ;
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

COMMENT ON FUNCTION z_asgard_admin.asgard_on_create_schema() IS 'ASGARD. Fonction appelée par l''event trigger qui répercute sur la table de gestion les créations de schémas réalisées par des commandes CREATE SCHEMA directes ou exécutées dans le cadre de l''installation d''une extension.' ;

-- Event Trigger: asgard_on_create_schema

DROP EVENT TRIGGER asgard_on_create_schema ;

CREATE EVENT TRIGGER asgard_on_create_schema ON DDL_COMMAND_END
    WHEN TAG IN ('CREATE SCHEMA', 'CREATE EXTENSION')
    EXECUTE PROCEDURE z_asgard_admin.asgard_on_create_schema() ;
    
COMMENT ON EVENT TRIGGER asgard_on_create_schema IS 'ASGARD. Event trigger qui répercute sur la table de gestion les créations de schémas réalisées par des commandes CREATE SCHEMA directes ou exécutées dans le cadre de l''installation d''une extension.' ;


------ 3.3 - EVENT TRIGGER SUR DROP SCHEMA ------

-- Function: z_asgard_admin.asgard_on_drop_schema()

CREATE OR REPLACE FUNCTION z_asgard_admin.asgard_on_drop_schema() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $BODY$
/* OBJET : Fonction exécutée par l'event trigger asgard_on_drop_schema qui
           répercute dans la table z_asgard_admin.gestion_schema (via la vue
           z_asgard.gestion_schema_etr) les suppressions de schémas
           réalisées par des commandes DROP SCHEMA directes ou exécutées
           dans le cadre de la désinstallation d'une extension.
DECLENCHEMENT : ON SQL DROP.
CONDITION : WHEN TAG IN ('DROP SCHEMA', 'DROP EXTENSION') */
DECLARE
	obj record ;
    e_mssg text ;
    e_hint text ;
    e_detl text ;
BEGIN
    ------ CONTROLES DES PRIVILEGES ------
    IF NOT has_schema_privilege('z_asgard', 'USAGE')
    THEN
        RAISE EXCEPTION 'EDS1. Vous devez être membre du groupe éditeur du schéma z_asgard pour réaliser cette opération.' ;
    END IF ;
    
    IF NOT has_table_privilege('z_asgard.gestion_schema_etr', 'UPDATE')
            OR NOT has_table_privilege('z_asgard.gestion_schema_etr', 'SELECT')
    THEN
        RAISE EXCEPTION 'EDS2. Vous devez être membre du groupe éditeur du schéma z_asgard pour réaliser cette opération.' ;
    END IF ;
    

	FOR obj IN SELECT * FROM pg_event_trigger_dropped_objects()
                    WHERE object_type = 'schema'
    LOOP
        ------ ENREGISTREMENT DE LA SUPPRESSION ------
		UPDATE z_asgard.gestion_schema_etr
			SET (creation, oid_schema, ctrl) = (False, NULL, ARRAY['DROP', 'x7-A;#rzo'])
			WHERE quote_ident(nom_schema) = obj.object_identity ;    
		IF FOUND THEN
			RAISE NOTICE '... La suppression du schéma % a été enregistrée dans la table de gestion (creation = False).', replace(obj.object_identity, '"', '');
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
$BODY$;

ALTER FUNCTION z_asgard_admin.asgard_on_drop_schema()
    OWNER TO g_admin;

COMMENT ON FUNCTION z_asgard_admin.asgard_on_drop_schema() IS 'ASGARD. Fonction appelée par l''event trigger qui répercute sur la table de gestion les suppressions de schémas réalisées par des commandes DROP SCHEMA directes ou exécutées dans le cadre de la désinstallation d''une extension.' ;

-- Event Trigger: asgard_on_drop_schema

DROP EVENT TRIGGER asgard_on_drop_schema ;

CREATE EVENT TRIGGER asgard_on_drop_schema ON SQL_DROP
    WHEN TAG IN ('DROP SCHEMA', 'DROP EXTENSION')
    EXECUTE PROCEDURE z_asgard_admin.asgard_on_drop_schema() ;
    
COMMENT ON EVENT TRIGGER asgard_on_drop_schema IS 'ASGARD. Event trigger qui répercute sur la table de gestion les suppressions de schémas réalisées par des commandes DROP SCHEMA directes ou exécutées dans le cadre de la désinstallation d''une extension.' ;


-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


---------------------------------------
------ 4 - FONCTIONS UTILITAIRES ------
---------------------------------------
/* 4.1 - LISTES DES DROITS SUR LES OBJETS D'UN SCHEMA
   4.2 - LISTE DES DROITS SUR UN OBJET
   4.8 - REINITIALISATION DES PRIVILEGES SUR UN SCHEMA
   4.13 - REAFFECTATION DES PRIVILEGES D'UN RÔLE
   4.16 - DIAGNOSTIC DES DROITS NON STANDARDS
   4.18 - EXPLICITATION DES CODES DE PRIVILÈGES */

------ 4.1 - LISTES DES DROITS SUR LES OBJETS D'UN SCHEMA ------

-- Function: z_asgard.asgard_synthese_role(regnamespace, regrole)

CREATE OR REPLACE FUNCTION z_asgard.asgard_synthese_role(n_schema regnamespace, n_role regrole)
    RETURNS TABLE(commande text)
    LANGUAGE plpgsql
    AS $_$
/* OBJET : Cette fonction renvoie une table contenant une
           liste de commandes GRANT et REVOKE permettant de
           recréer les droits de "n_role" sur les objets du
           schéma "n_schema" (et le schéma lui-même).
ARGUMENTS :
- "n_schema" est un nom de schéma valide, casté en regnamespace ;
- "n_role" est un nom de rôle valide, casté en regrole.
SORTIE : Une table avec un unique champ nommé "commande". */
BEGIN
    ------ SCHEMAS ------
    -- privilèges attribués (hors propriétaire) :
    RETURN QUERY
        SELECT format('GRANT %s ON SCHEMA %s TO %%I', privilege, n_schema)
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
        SELECT format('GRANT %s ON TABLE %s TO %%I', privilege, oid::regclass)
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
                unnest(ARRAY['SELECT', 'INSERT', 'UPDATE', 'DELETE',
                    'TRUNCATE', 'REFERENCES', 'TRIGGER']) AS expected_privilege
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
        SELECT format('GRANT %s ON TABLE %s TO %%I', privilege, oid::regclass)
            FROM pg_catalog.pg_class,
                aclexplode(relacl) AS acl (grantor, grantee, privilege, grantable)
            WHERE relnamespace = n_schema
                AND relkind = 'S'
                AND relacl IS NOT NULL
                AND n_role = grantee
                AND NOT n_role = relowner ;
    -- privilèges révoqués du propriétaire :
    RETURN QUERY
        SELECT format('REVOKE %s ON TABLE %s FROM %%I', expected_privilege, oid::regclass)
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
        SELECT format('GRANT %s (%I) ON TABLE %s TO %%I', privilege, attname, attrelid::regclass)
            FROM pg_catalog.pg_class JOIN pg_catalog.pg_attribute
                     ON pg_class.oid = pg_attribute.attrelid,
                aclexplode(attacl) AS acl (grantor, grantee, privilege, grantable)
            WHERE relnamespace = n_schema
                AND attacl IS NOT NULL
                AND n_role = grantee ;
    ------ FONCTIONS ------
    -- inclut les fonctions d'agrégation
    -- privilèges attribués (hors propriétaire) :
    RETURN QUERY
        SELECT format('GRANT %s ON FUNCTION %s TO %%I', privilege, oid::regprocedure)
            FROM pg_catalog.pg_proc,
                aclexplode(proacl) AS acl (grantor, grantee, privilege, grantable)
            WHERE pronamespace = n_schema
                AND proacl IS NOT NULL
                AND n_role = grantee
                AND NOT n_role = proowner ;
    -- privilèges révoqués du propriétaire :
    RETURN QUERY
        SELECT format('REVOKE %s ON FUNCTION %s FROM %%I', expected_privilege, oid::regprocedure)
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
        SELECT format('GRANT %s ON TYPE %s.%I TO %%I', privilege, n_schema, typname)
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
END
$_$;

ALTER FUNCTION z_asgard.asgard_synthese_role(regnamespace, regrole)
    OWNER TO g_admin_ext ;

COMMENT ON FUNCTION z_asgard.asgard_synthese_role(regnamespace, regrole) IS 'ASGARD. Fonction qui liste les commandes permettant de reproduire les droits d''un rôle sur les objets d''un schéma.' ;


-- Function: z_asgard.asgard_synthese_public(regnamespace)

CREATE OR REPLACE FUNCTION z_asgard.asgard_synthese_public(n_schema regnamespace)
    RETURNS TABLE(commande text)
    LANGUAGE plpgsql
    AS $_$
/* OBJET : Cette fonction renvoie une table contenant une
           liste de commandes GRANT et REVOKE permettant de
           recréer les droits de public sur les objets du
           schéma "schema" (et le schéma lui-même).
REMARQUE : La fonction ne s'intéresse pas aux objets de type
fonction (dont agrégats) et type (dont domaines), sur lesquels
public reçoit des droits par défaut qu'il n'est pas judicieux
de reproduire sur un autre rôle, ni de révoquer lors d'un
changement de lecteur/éditeur. Si des privilèges par défaut ont
été révoqués pour public, la révocation restera valable pour les
futurs lecteur/éditeurs puisqu'il n'y a pas d'attribution
de privilèges supplémentaires pour les lecteurs/éditeurs sur
ces objets.
ARGUMENT : "schema" est un nom de schéma valide, casté en
regnamespace.
SORTIE : Une table avec un unique champ nommé "commande". */
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
        SELECT format('GRANT %s ON TABLE %s TO %%I', privilege, oid::regclass)
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
END
$_$;

ALTER FUNCTION z_asgard.asgard_synthese_public(regnamespace)
    OWNER TO g_admin_ext ;

COMMENT ON FUNCTION z_asgard.asgard_synthese_public(regnamespace) IS 'ASGARD. Fonction qui liste les commandes permettant de reproduire les droits de public sur les objets d''un schéma.' ;


------ 4.2 - LISTE DES DROITS SUR UN OBJET ------

-- Function: z_asgard.asgard_synthese_role_obj(oid, text, regrole)

CREATE OR REPLACE FUNCTION z_asgard.asgard_synthese_role_obj(obj_oid oid, obj_type text, n_role regrole)
    RETURNS TABLE(commande text)
    LANGUAGE plpgsql
    AS $_$
/* OBJET : Cette fonction renvoie une table contenant une
           liste de commandes GRANT et REVOKE permettant de
           recréer les droits de "n_role" sur un objet de type
		   table, table étrangère, partition de table, vue,
           vue matérialisée, séquence, fonction (dont fonctions
           d'agrégations), type (dont domaines).
ARGUMENTS :
- "obj_oid" est l'identifiant interne de l'objet ;
- "obj_type" est le type de l'objet au format text ('table',
'view', 'materialized view', 'sequence', 'function', 'type',
'domain', 'foreign table', 'partitioned table', 'aggregate') ;
- "n_role" est un nom de rôle valide, casté en regrole.
SORTIE : Une table avec un unique champ nommé "commande". */
BEGIN       
    ------ TABLE, VUE, VUE MATERIALISEE ------
    IF obj_type IN ('table', 'view', 'materialized view', 'foreign table', 'partitioned table')
    THEN
        -- privilèges attribués (si n_role n'est pas le propriétaire de l'objet) :
        RETURN QUERY
            SELECT format('GRANT %s ON TABLE %s TO %%I', privilege, oid::regclass)
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
                    unnest(ARRAY['SELECT', 'INSERT', 'UPDATE', 'DELETE',
                        'TRUNCATE', 'REFERENCES', 'TRIGGER']) AS expected_privilege
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
            SELECT format('GRANT %s (%I) ON TABLE %s TO %%I', privilege, attname, attrelid::regclass)
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
            SELECT format('GRANT %s ON SEQUENCE %s TO %%I', privilege, oid::regclass)
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
    -- inclut les fonctions d'agrégation
    ELSIF obj_type IN ('function', 'aggregate')
    THEN
        -- privilèges attribués (si n_role n'est pas le propriétaire de l'objet) :
        RETURN QUERY
            SELECT format('GRANT %s ON FUNCTION %s TO %%I', privilege, oid::regprocedure)
                FROM pg_catalog.pg_proc,
                    aclexplode(proacl) AS acl (grantor, grantee, privilege, grantable)
                WHERE oid = obj_oid
                    AND proacl IS NOT NULL
                    AND n_role = grantee
                    AND NOT n_role = proowner ;
        -- privilèges révoqués du propriétaire (si n_role est le propriétaire de l'objet) :
        RETURN QUERY
            SELECT format('REVOKE %s ON FUNCTION %s FROM %%I', expected_privilege, oid::regprocedure)
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
            SELECT format('GRANT %s ON TYPE %s.%I TO %%I', privilege, typnamespace::regnamespace, typname)
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
    ELSE
       RAISE EXCEPTION 'FSR0. Le type d''objet % n''est pas pris en charge', obj_type ;
    END IF ;
END
$_$;

ALTER FUNCTION z_asgard.asgard_synthese_role_obj(oid, text, regrole)
    OWNER TO g_admin_ext ;

COMMENT ON FUNCTION z_asgard.asgard_synthese_role_obj(oid, text, regrole) IS 'ASGARD. Fonction qui liste les commandes permettant de reproduire les droits d''un rôle sur un objet.' ;


-- Function: z_asgard.asgard_synthese_public_obj(oid, text)

CREATE OR REPLACE FUNCTION z_asgard.asgard_synthese_public_obj(obj_oid oid, obj_type text)
    RETURNS TABLE(commande text)
    LANGUAGE plpgsql
    AS $_$
/* OBJET : Cette fonction renvoie une table contenant une
           liste de commandes GRANT et REVOKE permettant de
           recréer les droits de public sur un objet de type
		   table, table étrangère, partition de table, vue,
           vue matérialisée ou séquence.
REMARQUE : La fonction ne s'intéresse pas aux objets de type
fonction (dont agrégats) et type (dont domaines), sur lesquels
public reçoit des droits par défaut qu'il n'est pas judicieux
de reproduire sur un autre rôle, ni de révoquer lors d'un
changement de lecteur/éditeur. Si des privilèges par défaut ont
été révoqués pour public, la révocation restera valable pour les
futurs lecteur/éditeurs puisqu'il n'y a pas d'attribution
de privilèges supplémentaires pour les lecteurs/éditeurs sur
ces objets.
ARGUMENTS :
- "obj_oid" est l'identifiant interne de l'objet ;
- "obj_type" est le type de l'objet au format text ('table',
'view', 'materialized view', 'sequence', 'foreign table',
'partitioned table').
SORTIE : Une table avec un unique champ nommé "commande". */
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
    ELSE
       RAISE EXCEPTION 'FSP0. Le type d''objet % n''est pas pris en charge', obj_type ;
    END IF ;
END
$_$;

ALTER FUNCTION z_asgard.asgard_synthese_public_obj(oid, text)
    OWNER TO g_admin_ext ;

COMMENT ON FUNCTION z_asgard.asgard_synthese_public_obj(oid, text) IS 'ASGARD. Fonction qui liste les commandes permettant de reproduire les droits de public sur un objet.' ;


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
/* OBJET : Cette fonction permet de réinitialiser les droits
           sur un schéma selon les privilèges standards associés
           aux rôles désignés dans la table de gestion.
           Si elle est appliquée à un schéma existant non référencé
           dans la table de gestion, elle l'ajoute avec son
           propriétaire courant. Elle échoue si le schéma n'existe
           pas.
ARGUMENTS :
- n_schema : nom d'un schéma présumé existant ;
- b_preserve (optionnel) : un paramètre booléen. Pour un schéma encore
non référencé (ou pré-référencé comme non-créé) dans la table de gestion une valeur
True signifie que les privilèges des rôles lecteur et éditeur doivent être
ajoutés par dessus les droits actuels. Avec la valeur par défaut False,
les privilèges sont réinitialisés. Ce paramètre est ignoré pour un schéma déjà
référencé comme créé (et les privilèges sont réinitialisés) ;
- b_gs (optionnel) : un booléen indiquant si, dans l'hypothèse où un schéma
serait déjà référencé - nécessairement comme non créé - dans la table de gestion,
c'est le propriétaire du schéma qui doit devenir le "producteur" (False) ou le
producteur de la table de gestion qui doit devenir le propriétaire
du schéma (True). False par défaut. Ce paramètre est ignoré pour un schéma déjà
créé.
SORTIE : '__ REINITIALISATION REUSSIE.' (ou '__INITIALISATION REUSSIE.' pour
un schéma non référencé comme créé avec b_preserve = True) si la requête
s'est exécutée normalement. */
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
    SELECT replace(nspowner::regrole::text, '"', '') INTO n_owner
        FROM pg_catalog.pg_namespace
        WHERE n_schema = nspname::text ;
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
    IF n_schema = 'z_asgard' AND (roles.lecteur IS NULL OR NOT roles.lecteur = 'g_consult')
    THEN
        -- rétablissement des droits de g_consult
        RAISE NOTICE 'rétablissement des privilèges attendus pour g_consult :' ;
        
        GRANT USAGE ON SCHEMA z_asgard TO g_consult ;
        RAISE NOTICE '> GRANT USAGE ON SCHEMA z_asgard TO g_consult' ;
        
        GRANT SELECT ON TABLE z_asgard.gestion_schema_usr TO g_consult ;
        RAISE NOTICE '> GRANT SELECT ON TABLE z_asgard.gestion_schema_usr TO g_consult' ;
        
        GRANT SELECT ON TABLE z_asgard.gestion_schema_etr TO g_consult ;
        RAISE NOTICE '> GRANT SELECT ON TABLE z_asgard.gestion_schema_etr TO g_consult' ;
                
        GRANT SELECT ON TABLE z_asgard.asgardmenu_metadata TO g_consult ;
        RAISE NOTICE '> GRANT SELECT ON TABLE z_asgard.asgardmenu_metadata TO g_consult' ;
        
        GRANT SELECT ON TABLE z_asgard.asgardmanager_metadata TO g_consult ;
        RAISE NOTICE '> GRANT SELECT ON TABLE z_asgard.asgardmanager_metadata TO g_consult' ;
        
        GRANT SELECT ON TABLE z_asgard.gestion_schema_read_only TO g_consult ;
        RAISE NOTICE '> GRANT SELECT ON TABLE z_asgard.gestion_schema_read_only TO g_consult' ;
    
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
                unnest(ARRAY['TABLES', 'SEQUENCES', 'FUNCTIONS', 'TYPES', 'SCHEMAS'],
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
$_$;

ALTER FUNCTION z_asgard.asgard_initialise_schema(text, boolean, boolean)
    OWNER TO g_admin_ext ;

COMMENT ON FUNCTION z_asgard.asgard_initialise_schema(text, boolean, boolean) IS 'ASGARD. Fonction qui réinitialise les privilèges sur un schéma (et l''ajoute à la table de gestion s''il n''y est pas déjà).' ;


------ 4.13 - REAFFECTATION DES PRIVILEGES D'UN RÔLE ------

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
/* OBJET : Cette fonction transfère tous les privilèges d'un rôle
           à un autre, et en premier lieu ses fonctions de producteur,
           éditeur et lecteur. Si aucun rôle cible n'est spécifié, les
           privilèges sont simplement supprimés et g_admin devient
           producteur des schémas, le cas échéant.
ARGUMENTS :
- n_role : une chaîne de caractères présumée correspondre à un nom de
  rôle valide ;
- n_role_cible : une chaîne de caractères présumée correspondre à un
  nom de rôle valide ;
- b_hors_asgard : un booléen, valeur par défaut False. Si ce paramètre
  vaut True, la propriété et les privilèges sur les objets des schémas
  non gérés par ASGARD ou hors schémas (par ex la base), sont pris en
  compte. La propriété des objets reviendra à g_admin si aucun
  rôle cible n'est spécifié ;
- b_privileges : un booléen, valeur par défaut True. Indique si, dans
  l'hypothèse où le rôle cible est spécifié, celui-ci doit recevoir
  les privilèges et propriétés du rôle (True) ou seulement ses propriétés
  (False) ;
- b_default_acl : un booléen, valeur par défaut False. Indique si les
  privilèges par défaut doivent être pris en compte (True) ou non (False).
SORTIE : liste (au format text[]) des bases sur lesquelles le rôle a
encore des droits, sinon NULL. */
DECLARE
    item record ;
    n_producteur_cible text := coalesce(n_role_cible, 'g_admin') ;
    c record ;
    k int ;
    utilisateur text ;
    l_db text[] ;
BEGIN

    ------ TESTS PREALABLES -----
    -- existance du rôle
    IF NOT n_role IN (SELECT rolname FROM pg_catalog.pg_roles)
    THEN
        RAISE EXCEPTION 'FRR1. Echec. Le rôle % n''existe pas', n_role ;
    END IF ;
    
    -- existance du rôle cible
    IF n_role_cible IS NOT NULL AND NOT n_role_cible IN (SELECT rolname FROM pg_catalog.pg_roles)
    THEN
        RAISE EXCEPTION 'FRR2. Echec. Le rôle % n''existe pas', n_role_cible ;
    END IF ;
    
    
    IF NOT b_privileges
    THEN
        n_role_cible := NULL ;
    END IF ;
    
    ------ FONCTION DE PRODUCTEUR ------
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
    -- seulement si le rôle cible n'est pas déjà producteur du schéma
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
        EXECUTE format('REASSIGN OWNED BY %I TO %I', n_role, n_producteur_cible) ;
        RAISE NOTICE '> %', format('REASSIGN OWNED BY %I TO %I', n_role, n_producteur_cible) ;
        RAISE NOTICE '... Le cas échéant, la propriété des objets hors schémas référencés par ASGARD a été réaffectée.' ;
    END IF ;
    
    ------ PRIVILEGES RESIDUELS SUR LES SCHEMAS D'ASGARD -------
    k := 0 ;
    FOR item IN (SELECT * FROM z_asgard.gestion_schema_usr WHERE creation)
    LOOP
        FOR c IN (SELECT * FROM z_asgard.asgard_synthese_role(
                       quote_ident(item.nom_schema)::regnamespace, quote_ident(n_role)::regrole))
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
            RAISE NOTICE '... Les privilèges résiduels du rôle % sur les schémas référencés par ASGARD ont été révoqués.', n_role ;
        ELSE
            RAISE NOTICE '... Les privilèges résiduels du rôle % sur les schémas référencés par ASGARD ont été réaffectés.', n_role ;
        END IF ;
    END IF ;
    
    ------ PRIVILEGES RESIDUELS SUR LES SCHEMAS HORS ASGARD ------
    IF b_hors_asgard
    THEN
        k := 0 ;
        FOR item IN (SELECT * FROM pg_catalog.pg_namespace
                         LEFT JOIN z_asgard.gestion_schema_usr
                             ON nspname::text = nom_schema AND creation
                         WHERE nom_schema IS NULL)
        LOOP
            FOR c IN (SELECT * FROM z_asgard.asgard_synthese_role(
                           quote_ident(item.nspname::text)::regnamespace, quote_ident(n_role)::regrole))
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
                    defaclrole::regrole,
                    CASE WHEN defaclnamespace = 0 THEN ''
                        ELSE format(' IN SCHEMA %s', defaclnamespace::regnamespace) END,
                    privilege,
                    typ_lg,
                    n_role
                    ) AS revoke_commande,
                CASE WHEN n_role_cible IS NOT NULL THEN format(
                    'ALTER DEFAULT PRIVILEGES FOR ROLE %s%s GRANT %s ON %s TO %I',
                    defaclrole::regrole,
                    CASE WHEN defaclnamespace = 0 THEN ''
                        ELSE format(' IN SCHEMA %s', defaclnamespace::regnamespace) END,
                    privilege,
                    typ_lg,
                    n_role_cible
                    ) END AS grant_commande,
                pg_has_role(defaclrole, 'USAGE') AS utilisable,
                defaclrole
                FROM pg_default_acl LEFT JOIN z_asgard.gestion_schema_etr
                        ON defaclnamespace = oid_schema,
                    aclexplode(defaclacl) AS acl (grantor, grantee, privilege, grantable),
                    unnest(ARRAY['TABLES', 'SEQUENCES', 'FUNCTIONS', 'TYPES', 'SCHEMAS'],
                        ARRAY['r', 'S', 'f', 'T', 'n']) AS t (typ_lg, typ_crt)
                WHERE defaclobjtype = typ_crt
                    AND (oid_schema IS NOT NULL OR b_hors_asgard)
                    AND grantee = quote_ident(n_role)::regrole
            )
        LOOP
            IF item.utilisable
            THEN
                IF n_role_cible IS NOT NULL
                THEN
                    EXECUTE item.grant_commande ;
                    RAISE NOTICE '> %', item.grant_commande ;
                END IF ;
                
                EXECUTE item.revoke_commande ;
                RAISE NOTICE '> %', item.revoke_commande ;
            ELSE
                RAISE EXCEPTION 'FRR3. Echec. Vous n''avez pas les privilèges nécessaires pour modifier les privilèges par défaut alloués par le rôle %.', item.defaclrole::regrole::text
                    USING DETAIL = item.revoke_commande,
                        HINT = 'Tentez de relancer la fonction en tant que super-utilisateur.' ;
            END IF ;
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
            SELECT format('GRANT %s ON DATABASE %I TO %%I', privilege, datname) AS commande
                FROM pg_catalog.pg_database,
                    aclexplode(datacl) AS acl (grantor, grantee, privilege, grantable)
                WHERE datacl IS NOT NULL
                    AND grantee = quote_ident(n_role)::regrole
            UNION
            -- tablespaces
            SELECT format('GRANT %s ON TABLESPACE %I TO %%I', privilege, spcname) AS commande
                FROM pg_catalog.pg_tablespace,
                    aclexplode(spcacl) AS acl (grantor, grantee, privilege, grantable)
                WHERE spcacl IS NOT NULL
                    AND grantee = quote_ident(n_role)::regrole
            UNION
            -- foreign data wrappers
            SELECT format('GRANT %s ON FOREIGN DATA WRAPPER %I TO %%I', privilege, fdwname) AS commande
                FROM pg_catalog.pg_foreign_data_wrapper,
                    aclexplode(fdwacl) AS acl (grantor, grantee, privilege, grantable)
                WHERE fdwacl IS NOT NULL
                    AND grantee = quote_ident(n_role)::regrole
            UNION
            -- foreign servers
            SELECT format('GRANT %s ON FOREIGN SERVER %I TO %%I', privilege, srvname) AS commande
                FROM pg_catalog.pg_foreign_server,
                    aclexplode(srvacl) AS acl (grantor, grantee, privilege, grantable)
                WHERE srvacl IS NOT NULL
                    AND grantee = quote_ident(n_role)::regrole
            UNION
            -- langages
            SELECT format('GRANT %s ON LANGUAGE %I TO %%I', privilege, lanname) AS commande
                FROM pg_catalog.pg_language,
                    aclexplode(lanacl) AS acl (grantor, grantee, privilege, grantable)
                WHERE lanacl IS NOT NULL
                    AND grantee = quote_ident(n_role)::regrole
            UNION        
            -- large objects
            SELECT format('GRANT %s ON LARGE OBJECT %I TO %%I', privilege, pg_largeobject_metadata.oid::text) AS commande
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
        
END
$_$;

ALTER FUNCTION z_asgard_admin.asgard_reaffecte_role(text, text, boolean, boolean, boolean)
    OWNER TO g_admin ;

COMMENT ON FUNCTION z_asgard_admin.asgard_reaffecte_role(text, text, boolean, boolean, boolean) IS 'ASGARD. Fonction qui réaffecte les privilèges et propriétés d''un rôle à un autre.' ;


------ 4.16 - DIAGNOSTIC DES DROITS NON STANDARDS ------

-- Function: z_asgard_admin.asgard_diagnostic(text[])

CREATE OR REPLACE FUNCTION z_asgard_admin.asgard_diagnostic(cibles text[] DEFAULT NULL::text[])
    RETURNS TABLE (nom_schema text, nom_objet text, typ_objet text, critique boolean, anomalie text)
    LANGUAGE plpgsql
    AS $_$
/* OBJET : Pour tous les schémas référencés par ASGARD et
           existants dans la base, asgard_diagnostic liste
           les écarts avec les droits standards.
ARGUMENT : cibles (optionnel) permet de restreindre le diagnostic
à la liste de schémas spécifiés.
APPEL : SELECT * FROM z_asgard_admin.asgard_diagnostic() ;
SORTIE : une table avec quatre attributs,
    - nom_schema = nom du schéma ;
    - nom_objet = nom de l'objet concerné ;
    - typ_objet = le type d'objet ;
    - critique = True si l'anomalie est problématique pour le
      bon fonctionnement d'ASGARD, False si elle est bénigne ;
    - anomalie = description de l'anomalie. */
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
                            'fonction', 'domaine', 'type', 'conversion', 'opérateur', 'collationnement',
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
                                THEN '(z_asgard.asgard_parse_relident(attrelid::regclass))[2] || '' ('' || ' || catalogue.prefixe || 'name || '')'' AS objname, '
                            ELSE catalogue.prefixe || 'name::text AS objname, ' END || '
                        regexp_replace(' || CASE WHEN catalogue.catalogue = 'pg_default_acl' THEN 'defaclrole'
                            WHEN catalogue.catalogue = 'pg_attribute' THEN 'NULL'
                            ELSE  catalogue.prefixe || 'owner' END || '::regrole::text, ''^["]?(.*?)["]?$'', ''\1'') AS objowner' ||
                        CASE WHEN catalogue.droits THEN ', ' || catalogue.prefixe || 'acl AS objacl' ELSE '' END || '
                        FROM pg_catalog.' || catalogue.catalogue || '
                        WHERE ' || CASE WHEN catalogue.catalogue = 'pg_attribute'
                                    THEN 'quote_ident((z_asgard.asgard_parse_relident(attrelid::regclass))[1])::regnamespace::oid = ' || item.oid_schema::text
                                WHEN catalogue.catalogue = 'pg_namespace' THEN catalogue.prefixe || 'name = ' || quote_literal(item.nom_schema)
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
                                    ('z_asgard', 'z_asgard', 'schéma', 'g_consult', 'U'),
                                    ('z_asgard', 'gestion_schema_usr', 'vue', 'g_consult', 'r'),
                                    ('z_asgard', 'gestion_schema_etr', 'vue', 'g_consult', 'r'),
                                    ('z_asgard', 'asgardmenu_metadata', 'vue', 'g_consult', 'r'),
                                    ('z_asgard', 'asgardmanager_metadata', 'vue', 'g_consult', 'r'),
                                    ('z_asgard', 'gestion_schema_read_only', 'vue', 'g_consult', 'r')
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
$_$;

ALTER FUNCTION z_asgard_admin.asgard_diagnostic(text[])
    OWNER TO g_admin ;

COMMENT ON FUNCTION z_asgard_admin.asgard_diagnostic(text[]) IS 'ASGARD. Fonction qui liste les écarts vis-à-vis des droits standards sur les schémas actifs référencés par ASGARD.' ;


------ 4.18 - EXPLICITATION DES CODES DE PRIVILÈGES ------

-- Function: z_asgard.asgard_expend_privileges(text)

CREATE OR REPLACE FUNCTION z_asgard.asgard_expend_privileges(privileges_codes text)
    RETURNS TABLE(privilege text)
    LANGUAGE plpgsql
    AS $_$
/* OBJET : Fonction qui explicite les privilèges correspondant
           aux codes données en argument. Par exemple
           ARRAY['SELECT', 'UPDATE'] pour 'rw'. Si un code n'est pas
           reconnu, il est ignoré.
ARGUMENT : Les codes des privilèges, concaténés sous la forme d'une
unique chaîne de caractères.
SORTIE : Une table avec un unique champ nommé "privilege". */
BEGIN
    RETURN QUERY
        SELECT
            p.privilege
            FROM unnest(
                ARRAY['SELECT', 'INSERT', 'UPDATE', 'DELETE',
                        'TRUNCATE', 'REFERENCES', 'TRIGGER', 'USAGE',
                        'CREATE', 'EXECUTE'],
                ARRAY['r', 'a', 'w', 'd', 'D', 'x', 't', 'U', 'C', 'X']
                ) AS p (privilege, prvlg)
            WHERE privileges_codes ~ prvlg ;
END
$_$;

ALTER FUNCTION z_asgard.asgard_expend_privileges(text)
    OWNER TO g_admin_ext ;

COMMENT ON FUNCTION z_asgard.asgard_expend_privileges(text) IS 'ASGARD. Fonction qui explicite les privilèges correspondant aux codes données en argument.' ;


-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


