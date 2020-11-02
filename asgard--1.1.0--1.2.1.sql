\echo Use "CREATE EXTENSION asgard" to load this file. \quit
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
--
-- ASGARD - Système de gestion des droits pour PostgreSQL, version 1.2.1
-- > Script de mise à jour depuis la version 1.1.0.
--
-- Copyright République Française, 2020.
-- Secrétariat général du Ministère de la transition écologique, du
-- Ministère de la cohésion des territoires et des relations avec les
-- collectivités territoriales et du Ministère de la Mer.
-- Service du numérique.
--
-- contributeurs : Alain Ferraton (SNUM/MSP/DS/GSG) et Leslie Lemaire
-- (SNUM/UNI/DRC).
-- 
-- mél : drc.uni.snum.sg@developpement-durable.gouv.fr
-- 
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
-- A cet égard  l'attention de l'utilisateur est attirée sur les risques
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
-- Schémas contenant les objets : z_asgard et z_asgard_admin.
--
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
--
-- NOUVEAUTES :
-- - la fonction de diagnostic détecte désormais les droits manquants
-- du propriétaire d'une vue sur les relations sources et les
-- privilèges attribués WITH GRANT OPTION ;
-- - lors de la création d'une vue, l'utilisateur sera averti si son
-- propriétaire ne dispose pas des privilèges suffisants sur les
-- données sources ;
-- - suppression de la vue qgis_menubuilder_metadata et la table 
-- asgard_parametre, devenues inutiles pour AsgardMenu ;
-- - ajout du champ permission à la vue asgardmenu_metadata, qui
-- indique le profil de droits de l'utilisateur sur le schéma contenant
-- la table. Report dans le code d'AsgardMenu des jointures avec pg_class
-- et geometry_columns, pour que les modifications ultérieures ne
-- nécessitent plus de nouvelle version de l'extension PostgreSQL ;
-- - la fonction de ré-affectation/suppression des droits
-- asgard_reaffecte_role renvoie désormais la liste des bases sur
-- lesquelles le rôle a encore des droits ;
-- - ajout d'une vue asgardmanager_metadata contenant des
-- informations utiles au plugin AsgardManager ;
-- - g_admin reçoit maintenant CREATE sur la base de données
-- WITH GRANT OPTION, ce qui lui permet de déléguer à d'autres la
-- gestion des schémas, y compris sur des bases dont il n'est pas
-- propriétaire.
-- 
-- Anomalies corrigées :
-- - correctif de robustesse sur la détection des types générés
-- automatiquement par la fonction asgard_admin_proprietaire ;
-- - asgard_diagnostic ne signale plus les anomalies sur les types
-- générés automatiquement ;
-- - asgard_synthese_role et asgard_synthese_role_obj :
-- correction d'une anomalie qui entraînait la production
-- de requêtes invalides pour les types array ;
-- - dans asgard_diagnostic, suppression des appels à la fonction
-- parse_ident, qui n'existe pas sous PG 9.5. Cela a nécessité
-- la création d'une petite fonction supplémentaire,
-- z_asgard.asgard_parse_relident ;
-- - correction d'une anomalie qui faisait échouer la fonction
-- asgard_diagnostic sous PG 9.5 (valeur de type indéfini
-- renvoyée dans le résultat de la fonction) ;
-- - correction d'une anomalie qui faisait échouer les fonctions
-- asgard_deplace_obj et asgard_initialise_obj lorsqu'elles étaient
-- appliquées à un type sous PG 9.5 (valeur de type indéfini dans le
-- résultat d'une requête).
--
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -




-- MOT DE PASSE DE CONTRÔLE : 'x7-A;#rzo'

-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

---------------------------------------
------ 1 - PREPARATION DES ROLES ------
---------------------------------------

DO $$
BEGIN
    IF NOT has_database_privilege('g_admin', current_database(), 'CREATE WITH GRANT OPTION')
    THEN
        EXECUTE 'GRANT CREATE ON DATABASE ' || current_database() || ' TO g_admin WITH GRANT OPTION' ;
    END IF ;
END $$ ;

-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

----------------------------------------
------ 2 - PREPARATION DES OBJETS ------
----------------------------------------

DROP VIEW IF EXISTS z_asgard.qgis_menubuilder_metadata ;
DROP TABLE IF EXISTS z_asgard_admin.asgard_parametre ;

------ 2.6 - VUE POUR ASGARDMENU ------

DROP VIEW IF EXISTS z_asgard.asgardmenu_metadata ;

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
    
GRANT SELECT ON TABLE z_asgard.asgardmenu_metadata TO g_consult ;

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
    
GRANT SELECT ON TABLE z_asgard.asgardmanager_metadata TO g_consult ;

COMMENT ON VIEW z_asgard.asgardmanager_metadata IS 'ASGARD. Données utiles à l''extension QGIS AsgardManager.' ;
COMMENT ON COLUMN z_asgard.asgardmanager_metadata.id IS 'Identifiant entier unique.' ;
COMMENT ON COLUMN z_asgard.asgardmanager_metadata.nom_schema IS 'Nom du schéma.' ;
COMMENT ON COLUMN z_asgard.asgardmanager_metadata.oid_producteur IS 'Identifiant système du rôle producteur.' ;
COMMENT ON COLUMN z_asgard.asgardmanager_metadata.oid_editeur IS 'Identifiant système du rôle éditeur.' ;
COMMENT ON COLUMN z_asgard.asgardmanager_metadata.oid_lecteur IS 'Identitifiant système du rôle lecteur.' ;

-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

--------------------------------------------
------ 3 - CREATION DES EVENT TRIGGERS -----
--------------------------------------------

------ 3.4 - EVENT TRIGGER SUR CREATE OBJET ------

-- FUNCTION: z_asgard_admin.asgard_on_create_objet()

CREATE OR REPLACE FUNCTION z_asgard_admin.asgard_on_create_objet() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $BODY$
/* OBJET : Fonction exécutée par l'event trigger asgard_on_create_objet qui
           veille à attribuer aux nouveaux objets créés les droits prévus
           pour le schéma dans la table de gestion.
AVERTISSEMENT : Les commandes CREATE OPERATOR CLASS, CREATE OPERATOR FAMILY
et CREATE STATISTICS ne sont pas pris en charge pour l'heure.
DECLENCHEMENT : ON DDL COMMAND END.
CONDITION : WHEN TAG IN ('CREATE TABLE', 'CREATE TABLE AS', 'CREATE VIEW',
'CREATE MATERIALIZED VIEW', 'SELECT INTO', 'CREATE SEQUENCE', 'CREATE FOREIGN TABLE',
'CREATE FUNCTION', 'CREATE OPERATOR', 'CREATE AGGREGATE', 'CREATE COLLATION',
'CREATE CONVERSION', 'CREATE DOMAIN', 'CREATE TEXT SEARCH CONFIGURATION',
'CREATE TEXT SEARCH DICTIONARY', 'CREATE TYPE') */
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
        RAISE EXCEPTION 'ECO1. Vous devez être membre du groupe lecteur du schéma z_asgard pour réaliser cette opération.' ;
    END IF ;
    
    IF NOT has_table_privilege('z_asgard.gestion_schema_etr', 'SELECT')
    THEN
        RAISE EXCEPTION 'ECO2. Vous devez être membre du groupe lecteur du schéma z_asgard pour réaliser cette opération.' ;
    END IF ;
    

    FOR obj IN SELECT DISTINCT classid, objid, object_type, schema_name, object_identity
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
            SELECT attname::text INTO STRICT xowner
                FROM pg_catalog.pg_attribute
                WHERE attrelid = obj.classid AND attname ~ 'owner' ;
            
            -- récupération du propriétaire courant de l'objet
            -- génère une erreur si la requête ne renvoie rien
            EXECUTE 'SELECT ' || xowner || '::regrole::text FROM ' ||
                obj.classid::regclass::text || ' WHERE oid = ' || obj.objid::text
                INTO STRICT proprietaire ;
                   
            -- si le propriétaire courant n'est pas le producteur
            IF NOT roles.producteur::text = proprietaire
            THEN
            
                ------ PROPRIETAIRE DE L'OBJET (DROITS DU PRODUCTEUR) ------
                RAISE NOTICE 'réattribution de la propriété de % au rôle producteur du schéma :', replace(obj.object_identity, '"', '') ;
                l := 'ALTER ' || obj.object_type || ' ' || obj.object_identity ||
                        ' OWNER TO '  || quote_ident(roles.producteur) ;
                EXECUTE l ;
                RAISE NOTICE '> %', l ;
            END IF ;
            
            ------ DROITS DE L'EDITEUR ------
            IF roles.editeur IS NOT NULL
            THEN
                -- sur les tables :
                IF obj.object_type IN ('table', 'view', 'materialized view', 'foreign table')
                THEN
                    RAISE NOTICE 'application des privilèges standards pour le rôle éditeur du schéma :' ;
                    l := 'GRANT SELECT, UPDATE, DELETE, INSERT ON TABLE ' || obj.object_identity ||
                            ' TO ' || quote_ident(roles.editeur) ;
                    EXECUTE l ;
                    RAISE NOTICE '> %', l ;
                    
                -- sur les séquences :
                ELSIF obj.object_type IN ('sequence')
                THEN
                    RAISE NOTICE 'application des privilèges standards pour le rôle éditeur du schéma :' ;
                    l := 'GRANT SELECT, USAGE ON SEQUENCE ' || obj.object_identity ||
                            ' TO ' || quote_ident(roles.editeur) ;
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
                    l := 'GRANT SELECT ON TABLE ' || obj.object_identity ||
                            ' TO ' || quote_ident(roles.lecteur) ;
                    EXECUTE l ;
                    RAISE NOTICE '> %', l ;
                    
                -- sur les séquences :
                ELSIF obj.object_type IN ('sequence')
                THEN
                    RAISE NOTICE 'application des privilèges standards pour le rôle lecteur du schéma :' ;
                    l := 'GRANT SELECT ON SEQUENCE ' || obj.object_identity ||
                            ' TO ' || quote_ident(roles.lecteur) ;
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
                        relname,
                        liblg,
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
                    RAISE WARNING 'Le producteur du schéma de la vue % ne dispose pas des droits nécessaires pour accéder à ses données sources.',
                            CASE WHEN obj.object_type = 'materialized view' THEN 'matérialisée ' ELSE '' END || obj.object_identity
                        USING DETAIL = src.liblg || ' source ' || src.nom_schema || '.' || src.relname::text || ', producteur ' || src.oid_producteur::regrole::text ||
                            ', éditeur ' || coalesce(src.oid_editeur::regrole::text, 'non défini') || ', lecteur ' || coalesce(src.oid_lecteur::regrole::text, 'non défini') || '.',
                        HINT =
                            CASE WHEN src.oid_lecteur IS NULL
                                THEN 'Pour faire du producteur de la vue ' || CASE WHEN obj.object_type = 'materialized view' THEN 'matérialisée ' ELSE '' END
                                    || 'le lecteur du schéma source, vous pouvez lancer la commande suivante : UPDATE z_asgard.gestion_schema_usr SET lecteur = '
                                    || quote_literal(roles.producteur) || ' WHERE nom_schema = ' || quote_literal(src.nom_schema) || '.'
                                ELSE 'Pour rendre le producteur de la vue ' || CASE WHEN obj.object_type = 'materialized view' THEN 'matérialisée ' ELSE '' END
                                    || 'membre du rôle lecteur du schéma source, vous pouvez lancer la commande suivante : GRANT ' || src.oid_lecteur::regrole::text
                                    || ' TO ' || quote_ident(roles.producteur) || '.' END ;
                END LOOP ;            
            END IF ;
            
        END IF;

    END LOOP;

EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                            e_hint = PG_EXCEPTION_HINT,
                            e_detl = PG_EXCEPTION_DETAIL ;
    RAISE EXCEPTION 'ECO0 > %', e_mssg
        USING DETAIL = e_detl,
            HINT = e_hint ;
               
END
$BODY$;

-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

---------------------------------------
------ 4 - FONCTIONS UTILITAIRES ------
---------------------------------------

------ 4.1 - LISTES DES DROITS SUR LES OBJETS D'UN SCHEMA ------

-- FUNCTION: z_asgard.asgard_synthese_role(regnamespace, regrole)

CREATE OR REPLACE FUNCTION z_asgard.asgard_synthese_role(n_schema regnamespace, n_role regrole)
    RETURNS TABLE(commande text)
    LANGUAGE plpgsql
    AS $_$
/* OBJET : Cette fonction renvoie une table contenant une
           liste de commandes GRANT et REVOKE permettant de
           recréer les droits de "role_1" sur les objets du
           schéma "schema" (et le schéma lui-même).
ARGUMENTS :
- "schema" est un nom de schéma valide, casté en regnamespace ;
- "role_1" est un nom de rôle valide, casté en regrole.
SORTIE : Une table avec un unique champ nommé "commande". */
DECLARE
    n_role_trans text ;

BEGIN

    SELECT z_asgard.asgard_role_trans_acl(n_role)
        INTO n_role_trans ;
    
    ------ SCHEMAS ------
    -- privilèges attribués (hors propriétaire) :
    RETURN QUERY
        WITH t_acl AS (
        SELECT unnest(nspacl)::text AS acl
            FROM pg_catalog.pg_namespace
            WHERE oid = n_schema::oid
                AND nspacl IS NOT NULL
                AND NOT n_role::oid = nspowner
        )
        SELECT 'GRANT ' || privilege || ' ON SCHEMA ' || n_schema::text || ' TO %I'
            FROM t_acl, unnest(ARRAY['USAGE', 'CREATE'], ARRAY['U', 'C']) AS l (privilege, prvlg)
            WHERE acl ~ ('^' || n_role_trans || '[=].*' || prvlg || '.*[/]') ;
    -- privilèges révoqués du propriétaire :
    RETURN QUERY
        WITH t_acl AS (
        SELECT oid, unnest(CASE WHEN nspacl::text[] = ARRAY[]::text[]
                               OR NOT array_to_string(nspacl, ',') ~ ('^' || n_role_trans || '[=]')
                                   AND NOT array_to_string(nspacl, ',') ~ ('[,]' || n_role_trans || '[=]')
                           THEN ARRAY[NULL]::text[]
                           ELSE nspacl::text[] END) AS acl
            FROM pg_catalog.pg_namespace
            WHERE oid = n_schema::oid
                AND n_role::oid = nspowner
                AND nspacl IS NOT NULL
        )
        SELECT 'REVOKE ' || privilege || ' ON SCHEMA ' || n_schema::text || ' FROM %I'
            FROM t_acl, unnest(ARRAY['USAGE', 'CREATE'], ARRAY['U', 'C']) AS l (privilege, prvlg)
            WHERE (acl ~ ('^' || n_role_trans || '[=]')
                    AND NOT acl ~ ( '[=].*' || prvlg || '.*[/]')) OR acl IS NULL ;
    ------ TABLES ------
    -- inclut les vues, vues matérialisées, tables étrangères et partitions
    -- privilèges attribués (hors propriétaire) :
    RETURN QUERY
        WITH t_acl AS (
        SELECT oid, unnest(relacl)::text AS acl
            FROM pg_catalog.pg_class
            WHERE relnamespace = n_schema
                AND relkind IN ('r', 'v', 'm', 'f', 'p')
                AND relacl IS NOT NULL
                AND NOT n_role::oid = relowner
        )
        SELECT 'GRANT ' || privilege || ' ON TABLE ' || oid::regclass::text || ' TO %I'
            FROM t_acl, unnest(ARRAY['SELECT', 'INSERT', 'UPDATE', 'DELETE',
                                     'TRUNCATE', 'REFERENCES', 'TRIGGER'],
                               ARRAY['r', 'a', 'w', 'd', 'D', 'x', 't']) AS l (privilege, prvlg)
            WHERE acl ~ ('^' || n_role_trans || '[=].*' || prvlg || '.*[/]') ;
    -- privilèges révoqués du propriétaire :
    RETURN QUERY
        WITH t_acl AS (
        SELECT oid, unnest(CASE WHEN relacl::text[] = ARRAY[]::text[]
                               OR NOT array_to_string(relacl, ',') ~ ('^' || n_role_trans || '[=]')
                                   AND NOT array_to_string(relacl, ',') ~ ('[,]' || n_role_trans || '[=]')
                           THEN ARRAY[NULL]::text[]
                           ELSE relacl::text[] END) AS acl
            FROM pg_catalog.pg_class
            WHERE relnamespace = n_schema
                AND relacl IS NOT NULL
                AND relkind IN ('r', 'v', 'm', 'f', 'p')
                AND n_role::oid = relowner
        )
        SELECT 'REVOKE ' || privilege || ' ON TABLE ' || oid::regclass::text || ' FROM %I'
            FROM t_acl, unnest(ARRAY['SELECT', 'INSERT', 'UPDATE', 'DELETE',
                                     'TRUNCATE', 'REFERENCES', 'TRIGGER'],
                               ARRAY['r', 'a', 'w', 'd', 'D', 'x', 't']) AS l (privilege, prvlg)
            WHERE (acl ~ ('^' || n_role_trans || '[=]')
                    AND NOT acl ~ ( '[=].*' || prvlg || '.*[/]')) OR acl IS NULL ;
    ------ SEQUENCES ------
    -- privilèges attribués (hors propriétaire) :
    RETURN QUERY
        WITH t_acl AS (
        SELECT oid, unnest(relacl)::text AS acl
            FROM pg_catalog.pg_class
            WHERE relnamespace = n_schema
                AND relkind = 'S'
                AND relacl IS NOT NULL
                AND NOT n_role::oid = relowner
        )
        SELECT 'GRANT ' || privilege || ' ON SEQUENCE ' || oid::regclass::text || ' TO %I'
            FROM t_acl, unnest(ARRAY['SELECT', 'USAGE', 'UPDATE'],
                               ARRAY['r', 'U', 'w']) AS l (privilege, prvlg)
            WHERE acl ~ ('^' || n_role_trans || '[=].*' || prvlg || '.*[/]') ;
    -- privilèges révoqués du propriétaire :
    RETURN QUERY
        WITH t_acl AS (
        SELECT oid, unnest(CASE WHEN relacl::text[] = ARRAY[]::text[]
                               OR NOT array_to_string(relacl, ',') ~ ('^' || n_role_trans || '[=]')
                                   AND NOT array_to_string(relacl, ',') ~ ('[,]' || n_role_trans || '[=]')
                           THEN ARRAY[NULL]::text[]
                           ELSE relacl::text[] END) AS acl
            FROM pg_catalog.pg_class
            WHERE relnamespace = n_schema
                AND relacl IS NOT NULL
                AND relkind = 'S'
                AND n_role::oid = relowner
        )
        SELECT 'REVOKE ' || privilege || ' ON SEQUENCE ' || oid::regclass::text || ' FROM %I'
            FROM t_acl, unnest(ARRAY['SELECT', 'USAGE', 'UPDATE'],
                               ARRAY['r', 'U', 'w']) AS l (privilege, prvlg)
            WHERE (acl ~ ('^' || n_role_trans || '[=]')
                    AND NOT acl ~ ( '[=].*' || prvlg || '.*[/]')) OR acl IS NULL ;
    ------ COLONNES ------
    -- privilèges attribués :
    RETURN QUERY
        WITH t_acl AS (
        SELECT attname, attrelid, unnest(attacl)::text AS acl
            FROM pg_catalog.pg_class JOIN pg_catalog.pg_attribute
                     ON pg_class.oid = pg_attribute.attrelid
            WHERE relnamespace = n_schema
                AND attacl IS NOT NULL
        )
        SELECT 'GRANT ' || privilege || ' (' || quote_ident(attname::text) || ') ON TABLE '
                || attrelid::regclass::text || ' TO %I'
            FROM t_acl, unnest(ARRAY['SELECT', 'INSERT', 'UPDATE', 'REFERENCES'],
                               ARRAY['r', 'a', 'w', 'x']) AS l (privilege, prvlg)
            WHERE acl ~ ('^' || n_role_trans || '[=].*' || prvlg || '.*[/]') ;
    ------ FONCTIONS ------
    -- inclut les fonctions d'agrégation
    -- privilèges attribués (hors propriétaire) :
    RETURN QUERY
        WITH t_acl AS (
        SELECT oid, unnest(proacl)::text AS acl
            FROM pg_catalog.pg_proc
            WHERE pronamespace = n_schema
                AND proacl IS NOT NULL
                AND NOT n_role::oid = proowner
        )
        SELECT 'GRANT ' || privilege || ' ON FUNCTION ' || oid::regprocedure::text || ' TO %I'
            FROM t_acl, unnest(ARRAY['EXECUTE'], ARRAY['X']) AS l (privilege, prvlg)
            WHERE acl ~ ('^' || n_role_trans || '[=].*' || prvlg || '.*[/]') ;
    -- privilèges révoqués du propriétaire :
    RETURN QUERY
        WITH t_acl AS (
        SELECT oid, unnest(CASE WHEN proacl::text[] = ARRAY[]::text[]
                               OR NOT array_to_string(proacl, ',') ~ ('^' || n_role_trans || '[=]')
                                   AND NOT array_to_string(proacl, ',') ~ ('[,]' || n_role_trans || '[=]')
                           THEN ARRAY[NULL]::text[]
                           ELSE proacl::text[] END) AS acl
            FROM pg_catalog.pg_proc
            WHERE pronamespace = n_schema
                AND n_role::oid = proowner
                AND proacl IS NOT NULL
        )
        SELECT 'REVOKE ' || privilege || ' ON FUNCTION ' || oid::regprocedure::text || ' FROM %I'
            FROM t_acl, unnest(ARRAY['EXECUTE'], ARRAY['X']) AS l (privilege, prvlg)
            WHERE (acl ~ ('^' || n_role_trans || '[=]')
                    AND NOT acl ~ ( '[=].*' || prvlg || '.*[/]')) OR acl IS NULL ;
    ------ TYPES ------
    -- inclut les domaines
    -- privilèges attribués (hors propriétaire) :
    RETURN QUERY
        WITH t_acl AS (
        SELECT oid, unnest(typacl)::text AS acl, typname
            FROM pg_catalog.pg_type
            WHERE typnamespace = n_schema
                AND typacl IS NOT NULL
                AND NOT n_role::oid = typowner
        )
        SELECT 'GRANT ' || privilege || ' ON TYPE ' || n_schema::text || '.' || quote_ident(typname) || ' TO %I'
            FROM t_acl, unnest(ARRAY['USAGE'], ARRAY['U']) AS l (privilege, prvlg)
            WHERE acl ~ ('^' || n_role_trans || '[=].*' || prvlg || '.*[/]') ;
    -- privilèges révoqués du propriétaire :
    RETURN QUERY
        WITH t_acl AS (
        SELECT oid, unnest(CASE WHEN typacl::text[] = ARRAY[]::text[]
                               OR NOT array_to_string(typacl, ',') ~ ('^' || n_role_trans || '[=]')
                                   AND NOT array_to_string(typacl, ',') ~ ('[,]' || n_role_trans || '[=]')
                           THEN ARRAY[NULL]::text[]
                           ELSE typacl::text[] END) AS acl,
                typname
            FROM pg_catalog.pg_type
            WHERE typnamespace = n_schema
                AND n_role::oid = typowner
                AND typacl IS NOT NULL
        )
        SELECT 'REVOKE ' || privilege || ' ON TYPE ' || n_schema::text || '.' || quote_ident(typname) || ' FROM %I'
            FROM t_acl, unnest(ARRAY['USAGE'], ARRAY['U']) AS l (privilege, prvlg)
            WHERE (acl ~ ('^' || n_role_trans || '[=]')
                    AND NOT acl ~ ( '[=].*' || prvlg || '.*[/]')) OR acl IS NULL ;
END
$_$;

------ 4.2 - LISTE DES DROITS SUR UN OBJET ------

-- FUNCTION: z_asgard.asgard_synthese_role_obj(oid, text, regrole)

CREATE OR REPLACE FUNCTION z_asgard.asgard_synthese_role_obj(obj_oid oid, obj_type text, n_role regrole)
    RETURNS TABLE(commande text)
    LANGUAGE plpgsql
    AS $_$
/* OBJET : Cette fonction renvoie une table contenant une
           liste de commandes GRANT et REVOKE permettant de
           recréer les droits de "role_1" sur un objet de type
		   table, table étrangère, partition de table, vue,
           vue matérialisée, séquence, fonction (dont fonctions
           d'agrégations), type (dont domaines).
ARGUMENTS :
- "obj_oid" est l'identifiant interne de l'objet ;
- "obj_type" est le type de l'objet au format text ('table',
'view', 'materialized view', 'sequence', 'function', 'type',
'domain', 'foreign table', 'partitioned table', 'aggregate') ;
- "role_1" est un nom de rôle valide, casté en regrole.
SORTIE : Une table avec un unique champ nommé "commande". */
DECLARE
    n_role_trans text ;
BEGIN

    SELECT z_asgard.asgard_role_trans_acl(n_role)
        INTO n_role_trans ;
        
    ------ TABLE, VUE, VUE MATERIALISEE ------
    IF obj_type IN ('table', 'view', 'materialized view', 'foreign table', 'partitioned table')
    THEN
        -- privilèges attribués (si n_role n'est pas le propriétaire de l'objet) :
        RETURN QUERY
            WITH t_acl AS (
            SELECT oid, unnest(relacl)::text AS acl
                FROM pg_catalog.pg_class
                WHERE oid = obj_oid
                    AND relacl IS NOT NULL
                    AND NOT n_role::oid = relowner
            )
            SELECT 'GRANT ' || privilege || ' ON TABLE ' || oid::regclass::text || ' TO %I'
                FROM t_acl, unnest(ARRAY['SELECT', 'INSERT', 'UPDATE', 'DELETE',
                                         'TRUNCATE', 'REFERENCES', 'TRIGGER'],
                                   ARRAY['r', 'a', 'w', 'd', 'D', 'x', 't']) AS l (privilege, prvlg)
                WHERE acl ~ ('^' || n_role_trans || '[=].*' || prvlg || '.*[/]') ;
        -- privilèges révoqués du propriétaire (si n_role est le propriétaire de l'objet) :
        RETURN QUERY
            WITH t_acl AS (
            SELECT oid, unnest(CASE WHEN relacl::text[] = ARRAY[]::text[]
                                   OR NOT array_to_string(relacl, ',') ~ ('^' || n_role_trans || '[=]')
                                       AND NOT array_to_string(relacl, ',') ~ ('[,]' || n_role_trans || '[=]')
                               THEN ARRAY[NULL]::text[]
                               ELSE relacl::text[] END) AS acl
                FROM pg_catalog.pg_class
                WHERE oid = obj_oid
                    AND relacl IS NOT NULL
                    AND n_role::oid = relowner
            )
            SELECT 'REVOKE ' || privilege || ' ON TABLE ' || oid::regclass::text || ' FROM %I'
                FROM t_acl, unnest(ARRAY['SELECT', 'INSERT', 'UPDATE', 'DELETE',
                                         'TRUNCATE', 'REFERENCES', 'TRIGGER'],
                                   ARRAY['r', 'a', 'w', 'd', 'D', 'x', 't']) AS l (privilege, prvlg)
                WHERE (acl ~ ('^' || n_role_trans || '[=]')
                    AND NOT acl ~ ( '[=].*' || prvlg || '.*[/]')) OR acl IS NULL ;
        ------ COLONNES ------
        -- privilèges attribués :
        RETURN QUERY
            WITH t_acl AS (
            SELECT attname, attrelid, unnest(attacl)::text AS acl
                FROM pg_catalog.pg_attribute
                WHERE pg_attribute.attrelid = obj_oid
                    AND attacl IS NOT NULL
            )
            SELECT 'GRANT ' || privilege || ' (' || quote_ident(attname::text) || ') ON TABLE '
                    || attrelid::regclass::text || ' TO %I'
                FROM t_acl, unnest(ARRAY['SELECT', 'INSERT', 'UPDATE', 'REFERENCES'],
                                   ARRAY['r', 'a', 'w', 'x']) AS l (privilege, prvlg)
                WHERE acl ~ ('^' || n_role_trans || '[=].*' || prvlg || '.*[/]') ;
    ------ SEQUENCES ------
    ELSIF obj_type = 'sequence'
    THEN
        -- privilèges attribués (si n_role n'est pas le propriétaire de l'objet) :
        RETURN QUERY
            WITH t_acl AS (
            SELECT oid, unnest(relacl)::text AS acl
                FROM pg_catalog.pg_class
                WHERE oid = obj_oid
                    AND relacl IS NOT NULL
                    AND NOT n_role::oid = relowner
            )
            SELECT 'GRANT ' || privilege || ' ON SEQUENCE ' || oid::regclass::text || ' TO %I'
                FROM t_acl, unnest(ARRAY['SELECT', 'USAGE', 'UPDATE'],
                                   ARRAY['r', 'U', 'w']) AS l (privilege, prvlg)
                WHERE acl ~ ('^' || n_role_trans || '[=].*' || prvlg || '.*[/]') ;
        -- privilèges révoqués du propriétaire (si n_role est le propriétaire de l'objet) :
        RETURN QUERY
            WITH t_acl AS (
            SELECT oid, unnest(CASE WHEN relacl::text[] = ARRAY[]::text[]
                                   OR NOT array_to_string(relacl, ',') ~ ('^' || n_role_trans || '[=]')
                                       AND NOT array_to_string(relacl, ',') ~ ('[,]' || n_role_trans || '[=]')
                               THEN ARRAY[NULL]::text[]
                               ELSE relacl::text[] END) AS acl
                FROM pg_catalog.pg_class
                WHERE oid = obj_oid
                    AND relacl IS NOT NULL
                    AND n_role::oid = relowner
            )
            SELECT 'REVOKE ' || privilege || ' ON SEQUENCE ' || oid::regclass::text || ' FROM %I'
                FROM t_acl, unnest(ARRAY['SELECT', 'USAGE', 'UPDATE'],
                                   ARRAY['r', 'U', 'w']) AS l (privilege, prvlg)
                WHERE (acl ~ ('^' || n_role_trans || '[=]')
                    AND NOT acl ~ ( '[=].*' || prvlg || '.*[/]')) OR acl IS NULL ;
    ------ FONCTIONS ------
    -- inclut les fonctions d'agrégation
    ELSIF obj_type IN ('function', 'aggregate')
    THEN
        -- privilèges attribués (si n_role n'est pas le propriétaire de l'objet) :
        RETURN QUERY
            WITH t_acl AS (
            SELECT oid, unnest(proacl)::text AS acl
                FROM pg_catalog.pg_proc
                WHERE oid = obj_oid
                    AND proacl IS NOT NULL
                    AND NOT n_role::oid = proowner
            )
            SELECT 'GRANT ' || privilege || ' ON FUNCTION ' || oid::regprocedure::text || ' TO %I'
                FROM t_acl, unnest(ARRAY['EXECUTE'], ARRAY['X']) AS l (privilege, prvlg)
                WHERE acl ~ ('^' || n_role_trans || '[=].*' || prvlg || '.*[/]') ;
        -- privilèges révoqués du propriétaire (si n_role est le propriétaire de l'objet) :
        RETURN QUERY
            WITH t_acl AS (
            SELECT oid, unnest(CASE WHEN proacl::text[] = ARRAY[]::text[]
                                   OR NOT array_to_string(proacl, ',') ~ ('^' || n_role_trans || '[=]')
                                       AND NOT array_to_string(proacl, ',') ~ ('[,]' || n_role_trans || '[=]')
                               THEN ARRAY[NULL]::text[]
                               ELSE proacl::text[] END) AS acl
                FROM pg_catalog.pg_proc
                WHERE oid = obj_oid
                    AND n_role::oid = proowner
                    AND proacl IS NOT NULL
            )
            SELECT 'REVOKE ' || privilege || ' ON FUNCTION ' || oid::regprocedure::text || ' FROM %I'
                FROM t_acl, unnest(ARRAY['EXECUTE'], ARRAY['X']) AS l (privilege, prvlg)
                WHERE (acl ~ ('^' || n_role_trans || '[=]')
                    AND NOT acl ~ ( '[=].*' || prvlg || '.*[/]')) OR acl IS NULL ;
    ------ TYPES ------
    -- inclut les domaines
    ELSIF obj_type IN ('type', 'domain')
    THEN
        -- privilèges attribués (si n_role n'est pas le propriétaire de l'objet) :
        RETURN QUERY
            WITH t_acl AS (
            SELECT oid, unnest(typacl)::text AS acl, typname, typnamespace
                FROM pg_catalog.pg_type
                WHERE oid = obj_oid
                    AND typacl IS NOT NULL
                    AND NOT n_role::oid = typowner
            )
            SELECT 'GRANT ' || privilege || ' ON TYPE ' || typnamespace::regnamespace::text || '.' || quote_ident(typname) || ' TO %I'
                FROM t_acl, unnest(ARRAY['USAGE'], ARRAY['U']) AS l (privilege, prvlg)
                WHERE acl ~ ('^' || n_role_trans || '[=].*' || prvlg || '.*[/]') ;
        -- privilèges révoqués du propriétaire (si n_role est le propriétaire de l'objet) :
        RETURN QUERY
            WITH t_acl AS (
            SELECT oid, unnest(CASE WHEN typacl::text[] = ARRAY[]::text[]
                                   OR NOT array_to_string(typacl, ',') ~ ('^' || n_role_trans || '[=]')
                                       AND NOT array_to_string(typacl, ',') ~ ('[,]' || n_role_trans || '[=]')
                               THEN ARRAY[NULL]::text[]
                               ELSE typacl::text[] END) AS acl,
                    typname, typnamespace
                FROM pg_catalog.pg_type
                WHERE oid = obj_oid
                    AND n_role::oid = typowner
                    AND typacl IS NOT NULL
            )
            SELECT 'REVOKE ' || privilege || ' ON TYPE ' || typnamespace::regnamespace::text || '.' || quote_ident(typname) || ' FROM %I'
                FROM t_acl, unnest(ARRAY['USAGE'], ARRAY['U']) AS l (privilege, prvlg)
                WHERE (acl ~ ('^' || n_role_trans || '[=]')
                    AND NOT acl ~ ( '[=].*' || prvlg || '.*[/]')) OR acl IS NULL ;
    ELSE
       RAISE EXCEPTION 'FSR0. Le type d''objet % n''est pas pris en charge', obj_type ;
    END IF ;
END
$_$;

------ 4.3 - MODIFICATION DU PROPRIETAIRE D'UN SCHEMA ET SON CONTENU ------

-- FUNCTION: z_asgard.asgard_admin_proprietaire(text, text, boolean)

CREATE OR REPLACE FUNCTION z_asgard.asgard_admin_proprietaire(
                           n_schema text, n_owner text, b_setschema boolean DEFAULT True
                           )
    RETURNS int
    LANGUAGE plpgsql
    AS $_$
/* OBJET : Gestion des droits. Cette fonction permet d''attribuer
           un schéma et tous les objets qu'il contient à un [nouveau]
           propriétaire.
AVERTISSEMENT : Les objets de type operator class, operator family
et extended planner statistic ne sont pas pris en charge pour l'heure.
ARGUMENTS :
- "n_schema" est une chaîne de caractères correspondant au nom du
  schéma à considérer ;
- "n_owner" est une chaîne de caractères correspondant au nom du
  rôle (rôle de groupe ou rôle de connexion) qui doit être
  propriétaire des objets ;
- "b_setschema" est un paramètre booléen optionnel (vrai par défaut)
  qui indique si la fonction doit changer le propriétaire du schéma
  ou seulement des objets qu'il contient.
RESULTAT : la fonction renvoie un entier correspondant au nombre
d''objets effectivement traités. Les commandes lancées sont notifiées
au fur et à mesure. */
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
                USING DETAIL = 'Propriétaire courant : ' || s_owner || '.' ;  
    END IF ;
    
    -- le propriétaire désigné n'existe pas
    IF NOT n_owner IN (SELECT rolname::text FROM pg_catalog.pg_roles)
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
            USING HINT = 'Lancez asgard_admin_proprietaire(' || quote_literal(n_schema)
                         || ', ' || quote_literal(n_owner) || ') pour changer également le propriétaire du schéma.' ;
    END IF ;
    
    ------ PROPRIÉTAIRE DU SCHEMA ------
    IF b_setschema
    THEN
        EXECUTE 'ALTER SCHEMA ' || quote_ident(n_schema) || ' OWNER TO ' || quote_ident(n_owner) ;
        RAISE NOTICE '> %', 'ALTER SCHEMA ' || quote_ident(n_schema) || ' OWNER TO ' || quote_ident(n_owner) ;
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
            relkind IN ('r', 'f', 'p', 'm') AS b, -- servira à assurer que les tables
                                                  -- soient listées avant les objets qui
                                                  -- en dépendent
            'ALTER ' || kind_lg || ' ' || pg_class.oid::regclass || ' OWNER TO '
                || quote_ident(n_owner) AS commande
            FROM pg_catalog.pg_class,
                unnest(ARRAY['r', 'p', 'v', 'm', 'f', 'S'],
                       ARRAY['TABLE', 'TABLE', 'VIEW', 'MATERIALIZED VIEW', 'FOREIGN TABLE', 'SEQUENCE']) AS l (kind_crt, kind_lg)
            WHERE relnamespace = quote_ident(n_schema)::regnamespace
                AND relkind IN ('S', 'r', 'p', 'v', 'm', 'f')
                AND kind_crt = relkind
                AND NOT relowner = o_owner
        UNION
        -- fonctions et agrégats :
        SELECT
            proname::text AS n_objet,
            proowner AS obj_owner,
            False AS b,
            'ALTER FUNCTION ' || pg_proc.oid::regprocedure || ' OWNER TO '
                || quote_ident(n_owner) AS commande
            FROM pg_catalog.pg_proc
            WHERE pronamespace = quote_ident(n_schema)::regnamespace
                AND NOT proowner = o_owner
            -- à noter que les agrégats (proisagg vaut True) ont
            -- leur propre commande ALTER AGGREGATE OWNER TO, mais
            -- ALTER FUNCTION OWNER TO fonctionne également, on ne
            -- fait donc pas de distinction pour l'heure
        UNION
        -- types et domaines :
        SELECT
            typname::text AS n_objet,
            typowner AS obj_owner,
            False AS b,
            'ALTER ' || kind_lg || ' ' || typnamespace::regnamespace::text || '.'
                || quote_ident(typname) || ' OWNER TO '
                || quote_ident(n_owner) AS commande
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
            'ALTER CONVERSION ' || connamespace::regnamespace::text || '.'
                || quote_ident(conname) || ' OWNER TO '
                || quote_ident(n_owner) AS commande
            FROM pg_catalog.pg_conversion
            WHERE connamespace = quote_ident(n_schema)::regnamespace
                AND NOT conowner = o_owner
        UNION
        -- opérateurs :
        SELECT
            oprname::text AS n_objet,
            oprowner AS obj_owner,
            False AS b,
            'ALTER OPERATOR ' || pg_operator.oid::regoperator || ' OWNER TO '
                || quote_ident(n_owner) AS commande
            FROM pg_catalog.pg_operator
            WHERE oprnamespace = quote_ident(n_schema)::regnamespace
                AND NOT oprowner = o_owner
        UNION
        -- collations :
        SELECT
            collname::text AS n_objet,
            collowner AS obj_owner,
            False AS b,
            'ALTER COLLATION ' || collnamespace::regnamespace::text || '.'
                || quote_ident(collname) || ' OWNER TO '
                || quote_ident(n_owner) AS commande
            FROM pg_catalog.pg_collation
            WHERE collnamespace = quote_ident(n_schema)::regnamespace
                AND NOT collowner = o_owner
        UNION
        -- text search dictionary :
        SELECT
            dictname::text AS n_objet,
            dictowner AS obj_owner,
            False AS b,
            'ALTER TEXT SEARCH DICTIONARY ' || pg_ts_dict.oid::regdictionary || ' OWNER TO '
                || quote_ident(n_owner) AS commande
            FROM pg_catalog.pg_ts_dict
            WHERE dictnamespace = quote_ident(n_schema)::regnamespace
                AND NOT dictowner = o_owner
        UNION
        -- text search configuration :
        SELECT
            cfgname::text AS n_objet,
            cfgowner AS obj_owner,
            False AS b,
            'ALTER TEXT SEARCH CONFIGURATION ' || pg_ts_config.oid::regconfig || ' OWNER TO '
                || quote_ident(n_owner) AS commande
            FROM pg_catalog.pg_ts_config
            WHERE cfgnamespace = quote_ident(n_schema)::regnamespace
                AND NOT cfgowner = o_owner
            ORDER BY b DESC
    LOOP
        IF pg_has_role(item.obj_owner, 'USAGE')
        THEN
            EXECUTE item.commande ;
            RAISE NOTICE '> %', item.commande ;
            k := k + 1 ;
        ELSE
            RAISE EXCEPTION 'FAP4. Vous n''êtes pas habilité à modifier le propriétaire de l''objet %.', item.n_objet
                USING DETAIL = 'Propriétaire courant : ' || item.obj_owner::regrole::text || '.' ;    
        END IF ;
    END LOOP ;
    ------ RESULTAT ------
    RETURN k ;
END
$_$ ;

------ 4.8 - REINITIALISATION DES PRIVILEGES SUR UN SCHEMA ------

-- FUNCTION: z_asgard.asgard_initialise_schema(text, boolean, boolean)

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
            USING HINT = 'Il vous faut être membre du rôle propriétaire ' || n_owner || '.' ;
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
                    USING HINT = 'Il vous faut être membre du rôle producteur ' || roles.producteur || '.' ;
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
        
        EXECUTE 'GRANT USAGE ON SCHEMA ' || quote_ident(n_schema) || ' TO ' || quote_ident(roles.editeur) ;
        RAISE NOTICE '> %', 'GRANT USAGE ON SCHEMA ' || quote_ident(n_schema) || ' TO ' || quote_ident(roles.editeur) ;
        
        EXECUTE 'GRANT SELECT, UPDATE, DELETE, INSERT ON ALL TABLES IN SCHEMA ' || quote_ident(n_schema) || ' TO ' || quote_ident(roles.editeur) ;
        RAISE NOTICE '> %', 'GRANT SELECT, UPDATE, DELETE, INSERT ON ALL TABLES IN SCHEMA ' || quote_ident(n_schema) || ' TO ' || quote_ident(roles.editeur) ;
        
        EXECUTE 'GRANT SELECT, USAGE ON ALL SEQUENCES IN SCHEMA ' || quote_ident(n_schema) || ' TO ' || quote_ident(roles.editeur) ;
        RAISE NOTICE '> %', 'GRANT SELECT, USAGE ON ALL SEQUENCES IN SCHEMA ' || quote_ident(n_schema) || ' TO ' || quote_ident(roles.editeur) ;
    END IF ;
    
    ------ RECREATION DES PRIVILEGES DU LECTEUR ------
    IF roles.lecteur IS NOT NULL
    THEN
        RAISE NOTICE 'application des privilèges standards pour le rôle lecteur du schéma :' ;
        
        EXECUTE 'GRANT USAGE ON SCHEMA ' || quote_ident(n_schema) || ' TO ' || quote_ident(roles.lecteur) ;
        RAISE NOTICE '> %', 'GRANT USAGE ON SCHEMA ' || quote_ident(n_schema) || ' TO ' || quote_ident(roles.lecteur) ;
        
        EXECUTE 'GRANT SELECT ON ALL TABLES IN SCHEMA ' || quote_ident(n_schema) || ' TO ' || quote_ident(roles.lecteur) ;
        RAISE NOTICE '> %', 'GRANT SELECT ON ALL TABLES IN SCHEMA ' || quote_ident(n_schema) || ' TO ' || quote_ident(roles.lecteur) ;
        
        EXECUTE 'GRANT SELECT ON ALL SEQUENCES IN SCHEMA ' || quote_ident(n_schema) || ' TO ' || quote_ident(roles.lecteur) ;
        RAISE NOTICE '> %', 'GRANT SELECT ON ALL SEQUENCES IN SCHEMA ' || quote_ident(n_schema) || ' TO ' || quote_ident(roles.lecteur) ;
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
                WITH t AS (
                    SELECT
                        unnest(defaclacl)::text AS acl,
                        defaclnamespace,
                        defaclrole,
                        defaclobjtype,
                        pg_has_role(defaclrole, 'USAGE') AS utilisable
                        FROM pg_default_acl LEFT JOIN z_asgard.gestion_schema_etr
                             ON oid_schema = defaclnamespace
                        WHERE defaclnamespace = quote_ident(n_schema)::regnamespace::oid
                    )
                SELECT
                    *,
                    CASE WHEN acl ~ ('^[=]') THEN 'public'
                        ELSE rolname::text END AS role_cible
                    FROM t LEFT JOIN pg_catalog.pg_roles
                        ON acl ~ ('^' || z_asgard.asgard_role_trans_acl(quote_ident(rolname)::regrole) || '[=]')
                )
    LOOP
        IF item.role_cible IS NULL
        THEN
            RAISE EXCEPTION 'FIS5. Echec de l''identification du rôle visé par un privilège par défaut (schéma %).', n_schema
                    USING DETAIL = item.acl ;
        END IF ;
    
        FOR c IN (
            SELECT
                'ALTER DEFAULT PRIVILEGES FOR ROLE ' || item.defaclrole::regrole::text ||
                    CASE WHEN item.defaclnamespace = 0 THEN '' ELSE ' IN SCHEMA ' || item.defaclnamespace::regnamespace::text END ||
                    ' REVOKE ' || privilege || ' ON ' || typ_lg || ' FROM ' || quote_ident(item.role_cible) AS lr    
                FROM unnest(ARRAY['SELECT', 'INSERT', 'UPDATE', 'DELETE',
                                  'TRUNCATE', 'REFERENCES', 'TRIGGER', 'USAGE',
                                  'CREATE', 'EXECUTE'],
                            ARRAY['r', 'a', 'w', 'd', 'D', 'x', 't', 'U', 'C', 'X'])
                        AS p (privilege, prvlg),
                    unnest(ARRAY['TABLES', 'SEQUENCES', 'FUNCTIONS', 'TYPES', 'SCHEMAS'],
                            ARRAY['r', 'S', 'f', 'T', 'n'])
                        AS t (typ_lg, typ_crt)
                WHERE item.acl ~ ('[=].*' || prvlg || '.*[/]') AND item.defaclobjtype = typ_crt
            )
        LOOP        
            IF item.utilisable
            THEN
                EXECUTE c.lr ;
                RAISE NOTICE '> %', c.lr ;
            ELSE
                RAISE EXCEPTION 'FIS6. Echec. Vous n''avez pas les privilèges nécessaires pour modifier les privilèges par défaut alloués par le rôle %.', item.defaclrole::regrole::text
                    USING DETAIL = c.lr,
                        HINT = 'Tentez de relancer la fonction en tant que super-utilisateur.' ;
            END IF ;
            k := k + 1 ;
        END LOOP ;
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

------ 4.9 - REINITIALISATION DES PRIVILEGES SUR UN OBJET ------

-- FUNCTION: z_asgard.asgard_initialise_obj(text, text, text)

CREATE OR REPLACE FUNCTION z_asgard.asgard_initialise_obj(
                              obj_schema text,
                              obj_nom text,
                              obj_typ text
                              )
    RETURNS text
    LANGUAGE plpgsql
    AS $_$
/* OBJET : Cette fonction permet de réinitialiser les droits
           sur un objet selon les privilèges standards associés
           aux rôles désignés dans la table de gestion pour son schéma.

ARGUMENTS :
- "obj_schema" est le nom du schéma contenant l'objet, au format
texte et sans guillemets ;
- "obj_nom" est le nom de l'objet, au format texte et (sauf pour
les fonctions !) sans guillemets ;
- "obj_typ" est le type de l'objet au format text ('table',
'partitioned table' (assimilé à 'table'), 'view', 'materialized view',
'foreign table', 'sequence', 'function', 'aggregate', 'type', 'domain').
SORTIE : '__ REINITIALISATION REUSSIE.' si la requête s'est exécutée
normalement. */
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
        xtyp, xclass, xreg, xprefix || 'name' AS xname, xprefix || 'owner' AS xowner,
        xprefix || 'namespace' AS xschema
        INTO class_info
        FROM unnest(
                ARRAY['table', 'foreign table', 'view', 'materialized view',
                    'sequence', 'type', 'domain', 'function', 'aggregate'],
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
            USING HINT = 'Types acceptés : ''table'', ''partitioned table'' (assimilé à ''table''), ''view'', ''materialized view'', ''foreign table'', ''sequence'', ''function'', ''aggregate'', ''type'', ''domain''.' ;
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
                    THEN class_info.xclass || '.oid::regprocedure::text = '
                        || quote_literal(quote_ident(obj_schema) || '.' || obj_nom)
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
            USING HINT = 'Il vous faut être membre du rôle producteur ' || roles.producteur || '.' ;
    END IF ;
    
    ------ REMISE A PLAT DU PROPRIETAIRE ------
    IF NOT obj.prop = quote_ident(roles.producteur)
    THEN
        -- permission sur le propriétaire de l'objet
        IF NOT pg_has_role(obj.prop::regrole::oid, 'USAGE')
        THEN
            RAISE EXCEPTION 'FIO6. Echec. Vous ne disposez pas des permissions nécessaires sur l''objet % pour réaliser cette opération.', obj_nom
                USING HINT = 'Il vous faut être membre du rôle propriétaire de l''objet (' || obj.prop || ').' ;
        END IF ;
        
        RAISE NOTICE 'réattribution de la propriété de % au rôle producteur du schéma :', obj_nom ;
        l := 'ALTER ' || obj_typ || ' ' || obj.appel ||
                ' OWNER TO '  || quote_ident(roles.producteur) ;
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
            l := 'GRANT SELECT, UPDATE, DELETE, INSERT ON TABLE '
                    || quote_ident(obj_schema) || '.' || quote_ident(obj_nom) ||
                    ' TO ' || quote_ident(roles.editeur) ;
            EXECUTE l ;
            RAISE NOTICE '> %', l ;
        -- sur les séquences :
        ELSIF obj_typ IN ('sequence')
        THEN
            RAISE NOTICE 'application des privilèges standards pour le rôle éditeur du schéma :' ;
            l := 'GRANT SELECT, USAGE ON SEQUENCE '
                    || quote_ident(obj_schema) || '.' || quote_ident(obj_nom) ||
                    ' TO ' || quote_ident(roles.editeur) ;
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
            l := 'GRANT SELECT ON TABLE ' || quote_ident(obj_schema) || '.'
                    || quote_ident(obj_nom) ||
                    ' TO ' || quote_ident(roles.lecteur) ;
            EXECUTE l ;
            RAISE NOTICE '> %', l ;
        -- sur les séquences :
        ELSIF obj_typ IN ('sequence')
        THEN
            RAISE NOTICE 'application des privilèges standards pour le rôle lecteur du schéma :' ;
            l := 'GRANT SELECT ON SEQUENCE ' || quote_ident(obj_schema) || '.'
                    || quote_ident(obj_nom) ||
                    ' TO ' || quote_ident(roles.lecteur) ;
            EXECUTE l ;
            RAISE NOTICE '> %', l ;
        END IF ;
    END IF ;
                
    RETURN '__ REINITIALISATION REUSSIE.' ;
END
$_$;

------ 4.10 - DEPLACEMENT D'OBJET ------

-- FUNCTION: z_asgard.asgard_deplace_obj(text, text, text, text, int)

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
/* OBJET : Cette fonction permet de déplacer un objet vers un nouveau
           schéma en spécifiant la gestion voulue sur les droits de
           l'objet : transfert ou réinitialisation des privilèges.
           Dans le cas d'une table avec un ou plusieurs champs de
           type serial, elle prend aussi en charge les privilèges
           sur les séquences associées.
ARGUMENTS :
- "obj_schema" est le nom du schéma contenant l'objet, au format
texte et sans guillemets ;
- "obj_nom" est le nom de l'objet, au format texte et sans
guillemets ;
- "obj_typ" est le type de l'objet au format text ('table',
'partitioned table' (assimilé à 'table'), 'view', 'materialized view',
'foreign table', 'sequence', 'function', 'aggregate', 'type', 'domain') ;
- "schema_cible" est le nom du schéma où doit être déplacé l'objet,
au format texte et sans guillemets ;
- "variante" [optionnel] est un entier qui définit le comportement
attendu par l'utilisateur vis à vis des privilèges :
    - 1 (valeur par défaut) | TRANSFERT COMPLET + CONSERVATION :
    les privilèges des rôles producteur, éditeur et lecteur de
    l'ancien schéma sont transférés sur ceux du nouveau. Si un
    éditeur ou lecteur a été désigné pour le nouveau schéma mais
    qu'aucun n'était défini pour l'ancien, le rôle reçoit les
    privilèges standards pour sa fonction. Le cas échéant,
    les privilèges des autres rôles sont conservés ;
    - 2 | REINITIALISATION COMPLETE : les nouveaux
    producteur, éditeur et lecteur reçoivent les privilèges
    standard. Les privilèges des autres rôles sont supprimés ;
    - 3 | TRANSFERT COMPLET + NETTOYAGE : les privilèges des rôles
    producteur, éditeur et lecteur de l'ancien schéma sont transférés
    sur ceux du nouveau. Si un éditeur ou lecteur a été désigné pour
    le nouveau schéma mais qu'aucun n'était défini pour l'ancien,
    le rôle reçoit les privilèges standards pour sa fonction.
    Les privilèges des autres rôles sont supprimés ;
    - 4 | TRANSFERT PRODUCTEUR + CONSERVATION : les privilèges de
    l'ancien producteur sont transférés sur le nouveau. Les privilèges
    des autres rôles sont conservés tels quels. C'est le comportement
    d'une commande ALTER [...] SET SCHEMA (interceptée par l'event
    trigger asgard_on_alter_objet) ;
    - 5 | TRANSFERT PRODUCTEUR + REINITIALISATION : les privilèges
    de l'ancien producteur sont transférés sur le nouveau. Les
    nouveaux éditeur et lecteur reçoivent les privilèges standards.
    Les privilèges des autres rôles sont supprimés ;
    - 6 | REINITIALISATION PARTIELLE : les nouveaux
    producteur, éditeur et lecteur reçoivent les privilèges
    standard. Les privilèges des autres rôles sont conservés.
SORTIE : '__ DEPLACEMENT REUSSI.' si la requête s'est exécutée normalement. */
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
BEGIN

    -- pour la suite, on assimile les partitions à des tables
    IF obj_typ = 'partitioned table'
    THEN
        obj_typ := 'table' ;
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
        xtyp, xclass, xreg, xprefix || 'name' AS xname, xprefix || 'owner' AS xowner,
        xprefix || 'namespace' AS xschema
        INTO class_info
        FROM unnest(
                ARRAY['table', 'foreign table', 'view', 'materialized view',
                    'sequence', 'type', 'domain', 'function', 'aggregate'],
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
            USING HINT = 'Types acceptés : ''table'', ''partitioned table'' (assimilé à ''table''), ''view'', ''materialized view'', ''foreign table'', ''sequence'', ''function'', ''aggregate'', ''type'', ''domain''.' ;
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
                    THEN class_info.xclass || '.oid::regprocedure::text = '
                        || quote_literal(quote_ident(obj_schema) || '.' || obj_nom)
                ELSE class_info.xname || ' = ' || quote_literal(obj_nom)
                    || ' AND ' || class_info.xschema || '::regnamespace::text = '
                    || quote_literal(quote_ident(obj_schema)) END
        INTO obj ;
     
    IF obj.prop IS NULL
    THEN
        RAISE EXCEPTION 'FDO5. Echec. L''objet % n''existe pas.', obj_nom ;
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
            USING HINT = 'Il vous faut être membre du rôle producteur ' || roles_cible.producteur || '.' ;
    END IF ;
    
    -- permission sur le propriétaire de l'objet
    IF NOT pg_has_role(obj.prop::regrole::oid, 'USAGE')
    THEN
        RAISE EXCEPTION 'FDO7. Echec. Vous ne disposez pas des permissions nécessaires sur l''objet % pour réaliser cette opération.', obj_nom
            USING HINT = 'Il vous faut être membre du rôle propriétaire de l''objet (' || obj.prop || ').' ;
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
                pg_class.oid
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
    EXECUTE 'ALTER ' || obj_typ || ' ' || obj.appel || ' SET SCHEMA '  || quote_ident(schema_cible) ;
                
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
            l := z_asgard.asgard_grant_to_revoke(replace(l, quote_ident(obj_schema) || '.', quote_ident(schema_cible) || '.')) ;
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
            l := z_asgard.asgard_grant_to_revoke(replace(l, quote_ident(obj_schema) || '.', quote_ident(schema_cible) || '.')) ;
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
            l := z_asgard.asgard_grant_to_revoke(replace(l, quote_ident(obj_schema) || '.', quote_ident(schema_cible) || '.')) ;
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
            l := replace(l, quote_ident(obj_schema) || '.', quote_ident(schema_cible) || '.') ;
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
            l := 'GRANT SELECT, UPDATE, DELETE, INSERT ON TABLE '
                    || quote_ident(schema_cible) || '.' || quote_ident(obj_nom) ||
                    ' TO ' || quote_ident(roles_cible.editeur) ;
            EXECUTE l ;
            RAISE NOTICE '> %', l ;
        -- sur les séquences libres :
        ELSIF obj_typ IN ('sequence')
        THEN
            RAISE NOTICE 'application des privilèges standards pour le rôle éditeur du schéma :' ;
            l := 'GRANT SELECT, USAGE ON SEQUENCE '
                    || quote_ident(schema_cible) || '.' || quote_ident(obj_nom) ||
                    ' TO ' || quote_ident(roles_cible.editeur) ;
            EXECUTE l ;
            RAISE NOTICE '> %', l ;
        END IF ;
        -- sur les séquences des champs serial :
        IF seq_liste IS NOT NULL
        THEN
            FOREACH o IN ARRAY seq_liste
            LOOP
                l := 'GRANT SELECT, USAGE ON SEQUENCE '
                    || o::regclass::text || ' TO ' || quote_ident(roles_cible.editeur) ;
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
            l := z_asgard.asgard_grant_to_revoke(replace(l, quote_ident(obj_schema) || '.', quote_ident(schema_cible) || '.')) ;
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
            l := z_asgard.asgard_grant_to_revoke(replace(l, quote_ident(obj_schema) || '.', quote_ident(schema_cible) || '.')) ;
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
            l := replace(l, quote_ident(obj_schema) || '.', quote_ident(schema_cible) || '.') ;
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
            l := 'GRANT SELECT ON TABLE ' || quote_ident(schema_cible) || '.'
                    || quote_ident(obj_nom) ||
                    ' TO ' || quote_ident(roles_cible.lecteur) ;
            EXECUTE l ;
            RAISE NOTICE '> %', l ;
        -- sur les séquences libres :
        ELSIF obj_typ IN ('sequence')
        THEN
            RAISE NOTICE 'application des privilèges standards pour le rôle lecteur du schéma :' ;
            l := 'GRANT SELECT ON SEQUENCE ' || quote_ident(schema_cible) || '.'
                    || quote_ident(obj_nom) ||
                    ' TO ' || quote_ident(roles_cible.lecteur) ;
            EXECUTE l ;
            RAISE NOTICE '> %', l ;
        END IF ; 
        -- sur les séquences des champs serial :
        IF seq_liste IS NOT NULL
        THEN
            FOREACH o IN ARRAY seq_liste
            LOOP
                l := 'GRANT SELECT ON SEQUENCE '
                    || o::regclass::text || ' TO ' || quote_ident(roles_cible.lecteur) ;
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
            l := z_asgard.asgard_grant_to_revoke(replace(l, quote_ident(obj_schema) || '.', quote_ident(schema_cible) || '.')) ;
            EXECUTE l ;
            RAISE NOTICE '> %', l ;  
        END LOOP ;    
    END IF ;

    RETURN '__ DEPLACEMENT REUSSI.' ;
END
$_$;

------ 4.13 - REAFFECTATION DES PRIVILEGES D'UN RÔLE ------

DROP FUNCTION IF EXISTS z_asgard_admin.asgard_reaffecte_role(text, text, boolean, boolean, boolean) ;

-- FUNCTION: z_asgard_admin.asgard_reaffecte_role(text, text, boolean, boolean, boolean)

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
        EXECUTE 'REASSIGN OWNED BY ' || quote_ident(n_role) || ' TO ' || quote_ident(n_producteur_cible) ;
        RAISE NOTICE '> %', 'REASSIGN OWNED BY ' || quote_ident(n_role) || ' TO ' || quote_ident(n_producteur_cible) ;
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
                    WITH t AS (
                        SELECT
                            unnest(defaclacl)::text AS acl,
                            defaclnamespace,
                            defaclrole,
                            defaclobjtype,
                            pg_has_role(defaclrole, 'USAGE') AS utilisable
                            FROM pg_default_acl LEFT JOIN z_asgard.gestion_schema_etr
                                 ON defaclnamespace = oid_schema
                            WHERE array_to_string(defaclacl, ',') ~ z_asgard.asgard_role_trans_acl(quote_ident(n_role)::regrole)
                                AND oid_schema IS NOT NULL OR b_hors_asgard
                        )
                    SELECT * FROM t WHERE acl ~ ('^' || z_asgard.asgard_role_trans_acl(quote_ident(n_role)::regrole) || '[=]')
                    )
        LOOP
            FOR c IN (
                SELECT
                    'ALTER DEFAULT PRIVILEGES FOR ROLE ' || item.defaclrole::regrole::text ||
                        CASE WHEN item.defaclnamespace = 0 THEN '' ELSE ' IN SCHEMA ' || item.defaclnamespace::regnamespace::text END ||
                        ' GRANT ' || privilege || ' ON ' || typ_lg || ' TO ' || quote_ident(n_role_cible) AS lg,
                    'ALTER DEFAULT PRIVILEGES FOR ROLE ' || item.defaclrole::regrole::text ||
                        CASE WHEN item.defaclnamespace = 0 THEN '' ELSE ' IN SCHEMA ' || item.defaclnamespace::regnamespace::text END ||
                        ' REVOKE ' || privilege || ' ON ' || typ_lg || ' FROM ' || quote_ident(n_role) AS lr    
                    FROM unnest(ARRAY['SELECT', 'INSERT', 'UPDATE', 'DELETE',
                                      'TRUNCATE', 'REFERENCES', 'TRIGGER', 'USAGE',
                                      'CREATE', 'EXECUTE'],
                                ARRAY['r', 'a', 'w', 'd', 'D', 'x', 't', 'U', 'C', 'X'])
                            AS p (privilege, prvlg),
                        unnest(ARRAY['TABLES', 'SEQUENCES', 'FUNCTIONS', 'TYPES', 'SCHEMAS'],
                                ARRAY['r', 'S', 'f', 'T', 'n'])
                            AS t (typ_lg, typ_crt)
                    WHERE item.acl ~ ('[=].*' || prvlg || '.*[/]') AND item.defaclobjtype = typ_crt
                )
            LOOP        
                IF item.utilisable
                THEN
                    IF n_role_cible IS NOT NULL
                    THEN
                        EXECUTE c.lg ;
                        RAISE NOTICE '> %', c.lg ;
                    END IF ;
                    
                    EXECUTE c.lr ;
                    RAISE NOTICE '> %', c.lr ;
                ELSE
                    RAISE EXCEPTION 'FRR3. Echec. Vous n''avez pas les privilèges nécessaires pour modifier les privilèges par défaut alloués par le rôle %.', item.defaclrole::regrole::text
                        USING DETAIL = c.lr,
                            HINT = 'Tentez de relancer la fonction en tant que super-utilisateur.' ;
                END IF ;
                k := k + 1 ;
            END LOOP ;
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
            WITH t_acl AS (
            -- bases de données
            SELECT 'DATABASE'::text AS type_obj, datname::text AS n_obj, unnest(datacl)::text AS acl
                FROM pg_catalog.pg_database
                WHERE datacl IS NOT NULL
            UNION
            -- tablespaces
            SELECT 'TABLESPACE'::text AS type_obj, spcname::text AS n_obj, unnest(spcacl)::text AS acl
                FROM pg_catalog.pg_tablespace
                WHERE spcacl IS NOT NULL
            UNION
            -- foreign data wrappers
            SELECT 'FOREIGN DATA WRAPPER'::text AS type_obj, fdwname::text AS n_obj, unnest(fdwacl)::text AS acl
                FROM pg_catalog.pg_foreign_data_wrapper
                WHERE fdwacl IS NOT NULL
            UNION
            -- foreign servers
            SELECT 'FOREIGN SERVER'::text AS type_obj, srvname::text AS n_obj, unnest(srvacl)::text AS acl
                FROM pg_catalog.pg_foreign_server
                WHERE srvacl IS NOT NULL
            UNION
            -- langages
            SELECT 'LANGUAGE'::text AS type_obj, lanname::text AS n_obj, unnest(lanacl)::text AS acl
                FROM pg_catalog.pg_language
                WHERE lanacl IS NOT NULL
            UNION            
            -- large objects
            SELECT 'LARGE OBJECT'::text AS type_obj, pg_largeobject_metadata.oid::text AS n_obj, unnest(lomacl)::text AS acl
                FROM pg_catalog.pg_largeobject_metadata
                WHERE lomacl IS NOT NULL           
            )
            SELECT 'GRANT ' || privilege || ' ON ' || type_obj || ' ' || quote_ident(n_obj) || ' TO %I' AS commande
                FROM t_acl, unnest(ARRAY['CREATE', 'CONNECT', 'TEMPORARY', 'USAGE', 'SELECT', 'UPDATE'],
                                   ARRAY['C', 'c', 'T', 'U', 'r', 'w']) AS l (privilege, prvlg)
                WHERE acl ~ ('^' || z_asgard.asgard_role_trans_acl(quote_ident(n_role)::regrole) || '[=].*' || prvlg || '.*[/]')
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

DROP FUNCTION IF EXISTS z_asgard_admin.asgard_diagnostic() ;

-- FUNCTION: z_asgard_admin.asgard_diagnostic(text[])

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
                    cibles_trans := cibles_trans || ', ' || quote_literal(s) ;
                END IF ;
            END IF ;
        END LOOP ;
        
        cibles_trans := 'ARRAY[' || cibles_trans || ']' ;
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
            || CASE WHEN cibles_trans IS NOT NULL THEN ' AND gestion_schema_etr.nom_schema = ANY (' || cibles_trans || ')' ELSE '' END
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
                                'le propriétaire (' || objet.objowner || ') n''est pas le producteur désigné pour le schéma (' || item.producteur || ')' ;
                    END IF ;
                
                  -- présence de privilièges par défaut
                    IF catalogue.catalogue = 'pg_default_acl'
                    THEN
                        RETURN QUERY
                            WITH a AS (
                                SELECT
                                    unnest(objet.objacl)::text AS acl
                            ),
                            b AS (
                                SELECT
                                    CASE WHEN a.acl ~ '^[=]' THEN 'pseudo-rôle public'
                                        ELSE 'rôle ' || substring(a.acl, '^["]?(.*?)["]?[=]') END AS cible,
                                    privilege
                                    FROM unnest(
                                            ARRAY['SELECT', 'INSERT', 'UPDATE', 'DELETE',
                                                    'TRUNCATE', 'REFERENCES', 'TRIGGER', 'USAGE',
                                                    'CREATE', 'EXECUTE'],
                                            ARRAY['r', 'a', 'w', 'd', 'D', 'x', 't', 'U', 'C', 'X']
                                            ) AS p (privilege, prvlg)
                                        LEFT JOIN a ON a.acl ~ ('[=][rawdDxtUCX*]*' || p.prvlg)
                                    WHERE a.acl IS NOT NULL
                            )
                            SELECT
                                item.nom_schema::text,
                                NULL::text,
                                'privilège par défaut'::text,
                                False,
                                catalogue.lib_obj || ' : ' || privilege || ' pour le ' || cible || 
                                        ' accordé par le rôle ' || objet.objowner
                                FROM b ;

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
                                    ('z_asgard', 'asgardmanager_metadata', 'vue', 'g_consult', 'r')
                                ) AS t (a_schema, a_objet, a_type, role, droits)
                            WHERE a_schema = item.nom_schema AND a_objet = objet.objname::text AND a_type = catalogue.lib_obj ;
                    
                        RETURN QUERY
                            WITH a1 AS (
                                SELECT 
                                    unnest(objet.objacl)::text AS acl         
                            ),
                            a2 AS (
                                SELECT *
                                    FROM unnest(
                                            ARRAY['SELECT', 'INSERT', 'UPDATE', 'DELETE',
                                                    'TRUNCATE', 'REFERENCES', 'TRIGGER', 'USAGE',
                                                    'CREATE', 'EXECUTE'],
                                            ARRAY['r', 'a', 'w', 'd', 'D', 'x', 't', 'U', 'C', 'X']
                                            ) AS p (privilege, prvlg)
                                        LEFT JOIN unnest(
                                                ARRAY['le propriétaire', 'le lecteur du schéma', 'l''éditeur du schéma', 'un rôle d''ASGARD', 'le pseudo-rôle public'],
                                                ARRAY[objet.objowner, item.lecteur, item.editeur, asgard.role, 'public'],
                                                -- dans le cas d'un attribut, objet.objowner ne contient pas le propriétaire mais
                                                -- le nom de la relation. l'enregistrement sera toutefois systématiquement écarté,
                                                -- puisqu'il n'y a pas de droits standards du propriétaire sur les attributs
                                                ARRAY[catalogue.drt_producteur, catalogue.drt_lecteur, catalogue.drt_editeur, asgard.droits, catalogue.drt_public],
                                                ARRAY[False, False, False, True, False]
                                                ) AS b1 (fonction, f_role, f_droits, f_critique)
                                            ON f_droits ~ prvlg
                                    WHERE f_role IS NOT NULL AND f_droits IS NOT NULL
                                        AND (NOT objet.objacl IS NULL OR NOT fonction = ANY(ARRAY['le propriétaire', 'le pseudo-rôle public']))
                            ),
                            b AS (
                                SELECT
                                    acl,
                                    CASE WHEN a1.acl ~ '^[=]' THEN 'pseudo-rôle public'
                                        ELSE 'rôle ' || substring(a1.acl, '^["]?(.*?)["]?[=]') END AS cible,
                                    privilege,
                                    prvlg
                                    FROM unnest(
                                            ARRAY['SELECT', 'INSERT', 'UPDATE', 'DELETE',
                                                    'TRUNCATE', 'REFERENCES', 'TRIGGER', 'USAGE',
                                                    'CREATE', 'EXECUTE'],
                                            ARRAY['r', 'a', 'w', 'd', 'D', 'x', 't', 'U', 'C', 'X']
                                            ) AS p (privilege, prvlg)
                                        LEFT JOIN a1 ON a1.acl ~ ('[=][rawdDxtUCX*]*' || p.prvlg)
                                    WHERE a1.acl IS NOT NULL
                            )
                            SELECT
                                item.nom_schema::text,
                                objet.objname::text,
                                catalogue.lib_obj,
                                coalesce(a2.f_critique, False),
                                CASE
                                    WHEN b.prvlg IS NULL
                                        THEN 'privilège ' || a2.privilege || ' manquant pour ' || a2.fonction || ' (' || a2.f_role || ')'
                                    ELSE 'privilège ' || b.privilege || ' supplémentaire pour le ' || b.cible END
                                FROM a2 FULL OUTER JOIN b
                                    ON b.prvlg = a2.prvlg AND
                                        CASE WHEN a2.f_role = 'public' THEN (b.acl ~ '^[=]')
                                            ELSE (b.acl ~ ('^' || z_asgard.asgard_role_trans_acl(quote_ident(a2.f_role)::regrole) || '[=]')) END
                                WHERE a2.prvlg IS NULL OR b.prvlg IS NULL
                            UNION
                            SELECT
                                item.nom_schema::text,
                                objet.objname::text,
                                catalogue.lib_obj,
                                False,
                                'le ' || b.cible || ' est habilité à transmettre le privilège ' || b.privilege || ' (GRANT OPTION)'
                                FROM b
                                WHERE b.acl ~ ('[=][rawdDxtUCX*]*' || b.prvlg || '[*]') ;
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
                                'le producteur du schéma de la ' || catalogue.lib_obj || ' (' || item.producteur
                                    || ') n''est pas membre des groupes lecteur, éditeur ou producteur de la '
                                    || liblg || ' source ' || relname::text
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


------ 4.17 - EXTRACTION DE NOMS D'OBJETS A PARTIR D'IDENTIFIANTS ------

-- FUNCTION: z_asgard.asgard_parse_relident(regclass)

CREATE OR REPLACE FUNCTION z_asgard.asgard_parse_relident(ident regclass)
    RETURNS text[]
    LANGUAGE plpgsql
    AS $_$
/* OBJET : Cette fonction déduit un nom de schéma et un nom de relation
           d'un identifiant de relation. Pour PG 9.6+, elle fait double
           emploi avec la fonction parse_ident.
ARGUMENT : un identifiant de relation casté en regclass.
SORTIE : une liste de deux éléments : r[1] est le schéma et r[2] la relation. */
DECLARE
    n_schema text ;
    n_relation text ;
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
END
$_$;

ALTER FUNCTION z_asgard.asgard_parse_relident(regclass)
    OWNER TO g_admin_ext ;

COMMENT ON FUNCTION z_asgard.asgard_parse_relident(regclass) IS 'ASGARD. Fonction qui retourne le nom du schéma et le nom de la relation à partir d''un identifiant de relation.' ;

-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -