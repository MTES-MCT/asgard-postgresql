\echo Use "CREATE EXTENSION asgard" to load this file. \quit
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
--
-- ASGARD - Système de gestion des droits pour PostgreSQL, version 1.1.0
-- > Script de mise à jour depuis la version 1.0.0.
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
-- PostgreSQL et requiert l'installation préalable de l'extension PostGIS
-- ("http://postgis.net/").
--
-- Schémas contenant les objets : z_asgard et z_asgard_admin.
--
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
--
-- NOUVEAUTES :
-- - amélioration des mécanismes de mise en cohérence des champs bloc et
-- nom_schema ;
-- - la fonction asgard_initialise_schema prend désormais en charge
-- la suppression des privilèges par défaut ;
-- - ajout de la vue asgardmenu_metadata, qui servira à la prochaine
-- version de l'extension QGIS AsgardMenu ;
-- - ajout de la fonction asgard_diagnostic (diagnostic des écarts
-- vis-à-vis des droits standards prévus par ASGARD) ;
-- - amélioration de la fonction asgard_deplace_obj pour qu'elle
-- prenne véritablement en charge les types et fonctions.
-- 
-- Anomalies corrigées :
-- - problème d'affichage des signes '&' par AsgardMenu. À ce stade, la vue
-- qgis_menubuilder_metadata les remplace par 'et' ;
-- - corrections sur les descriptifs des champs de gestion_schema et
-- gestion_schema_usr suite à l'explicitation de la nomenclature ;
-- - correction d'une anomalie qui faisait échouer le référencement d'un
-- schéma pré-enregistré dans la table de gestion avec asgard_initialise_schema ;
-- - correction d'une anomalie qui faisait échouer l'application des droits
-- des rôles lecteur et éditeur en cas de référencement d'un schéma
-- pré-enregistré dans la table de gestion avec asgard_initialise_schema ;
-- - correction d'une anomalie qui faisait échouer les opérations sur les
-- droits pour les colonnes aux noms non standardisés ;
-- - correction d'une anomalie qui empêchait la détection des privilèges
-- sur les objets hors schémas par la fonction de réaffectation des privilèges
-- pour certaines formes de noms non normalisés ;
-- - dans la fonction d'import de la nomenclature, correction d'une
-- coquille sur le nom du schéma c_socio_eco.
--
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -




-- MOT DE PASSE DE CONTRÔLE : 'x7-A;#rzo'

-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

----------------------------------------
------ 2 - PREPARATION DES OBJETS ------
----------------------------------------

------ 2.2 - TABLE GESTION_SCHEMA ------

COMMENT ON COLUMN z_asgard_admin.gestion_schema.niv1 IS 'Nomenclature. Premier niveau d''arborescence (forme littérale).' ;
COMMENT ON COLUMN z_asgard_admin.gestion_schema.niv1_abr IS 'Nomenclature. Premier niveau d''arborescence (forme normalisée).' ;
COMMENT ON COLUMN z_asgard_admin.gestion_schema.niv2 IS 'Nomenclature. Second niveau d''arborescence (forme littérale).' ;
COMMENT ON COLUMN z_asgard_admin.gestion_schema.niv2_abr IS 'Nomenclature. Second niveau d''arborescence (forme normalisée).' ;

------ 2.4 - VUES D'ALIMENTATION DE GESTION_SCHEMA ------

COMMENT ON COLUMN z_asgard.gestion_schema_usr.niv1 IS 'Nomenclature. Premier niveau d''arborescence (forme littérale).' ;
COMMENT ON COLUMN z_asgard.gestion_schema_usr.niv1_abr IS 'Nomenclature. Premier niveau d''arborescence (forme normalisée).' ;
COMMENT ON COLUMN z_asgard.gestion_schema_usr.niv2 IS 'Nomenclature. Second niveau d''arborescence (forme littérale).' ;
COMMENT ON COLUMN z_asgard.gestion_schema_usr.niv2_abr IS 'Nomenclature. Second niveau d''arborescence (forme normalisée).' ;

------ 2.5 - VUE POUR MENUBUILDER ------

-- View: z_asgard.qgis_menubuilder_metadata

CREATE OR REPLACE VIEW z_asgard.qgis_menubuilder_metadata AS (
    WITH
    index_niv1 AS (
        SELECT
           (row_number() OVER(ORDER BY niv1 IS NULL,
                                       coalesce(niv1, nom_schema)) - 1)::text AS ind1b,
            coalesce(niv1, nom_schema) AS niv1b
            FROM z_asgard_admin.gestion_schema
            WHERE creation
            GROUP BY niv1 IS NULL, coalesce(niv1, nom_schema)
        ),
   index_niv2 AS (
        SELECT
           (row_number() OVER(PARTITION BY coalesce(niv1, nom_schema)
                              ORDER BY niv2 IS NULL,
                                       coalesce(niv2, relname)) - 1)::text AS ind2b,
            coalesce(niv2, relname) AS niv2b,
            coalesce(niv1, nom_schema) AS niv1bref
            FROM pg_catalog.pg_class JOIN z_asgard_admin.gestion_schema
                    ON relnamespace::regnamespace::text = quote_ident(nom_schema)
            WHERE creation
                AND relkind IN ('r', 'v', 'm', 'f', 'p')
                AND has_table_privilege(pg_class.oid, 'SELECT')
                AND has_schema_privilege(relnamespace, 'USAGE')
            GROUP BY niv2 IS NULL, coalesce(niv1, nom_schema), coalesce(niv2, relname)
        )
    SELECT
        row_number() OVER(ORDER BY niv1 IS NULL, niv1b, niv2 IS NULL, niv2b, relname) AS id,
        relname || CASE WHEN f_geometry_column IS NOT NULL AND NOT f_geometry_column = 'geom'
                        THEN '.' || f_geometry_column ELSE '' END AS name,
	    'consultation'::text AS profile,
		'[[0, "' || upper(current_database()::text) || '"], [' ||
            ind1b || ', "' || replace(niv1b, '&', 'et') || '"], [' ||
            ind2b || ', "' || replace(niv2b, '&', 'et') || '"]' || 
            CASE WHEN niv2 IS NOT NULL
                THEN ', [' || (row_number() OVER(PARTITION BY niv1b, niv2 ORDER BY relname) -1)::text
                    || ', "' || relname || '"]'
                ELSE '' END || ']'
        AS model_index,
        'vector:postgres:' || relname ||':'
            || CASE WHEN 'dbname' = ANY(connex_param) OR id IS NULL THEN 'dbname=' || quote_literal(current_database()) || ' ' ELSE '' END
            || CASE WHEN nom_service IS NOT NULL THEN 'service=' || quote_literal(nom_service) ELSE '' END
            || CASE WHEN 'host' = ANY(connex_param) OR id IS NULL  THEN ' host=' ||
                            CASE WHEN host(inet_server_addr()) IN ('127.0.0.1', '::1') THEN 'localhost'
                                ELSE host(inet_server_addr()) END
                    ELSE '' END
            || CASE WHEN 'port' = ANY(connex_param) OR id IS NULL  THEN ' port=' || inet_server_port() ELSE '' END
            || CASE WHEN 'user' = ANY(connex_param) THEN ' user=' || quote_literal(session_user) ELSE '' END
            || CASE WHEN 'sslmode' = ANY(connex_param) OR id IS NULL THEN ' sslmode=' ||
                            CASE WHEN host(inet_server_addr()) IN ('127.0.0.1', '::1') THEN 'disable'
                                WHEN sslmode IS NOT NULL THEN sslmode
                                ELSE 'require' END
                    ELSE '' END
            || CASE WHEN srid IS NOT NULL THEN ' srid=' || srid ELSE '' END
            || CASE WHEN geometry_columns.type IS NOT NULL THEN ' type=' || geometry_columns.type ELSE '' END
            || ' table="' || nom_schema || '"."' || relname
            || CASE WHEN f_geometry_column IS  NOT NULL THEN '" (' || quote_ident(f_geometry_column) || ') sql=::'
                   ELSE '" sql=:::::NoGeometry' END
            AS datasource_uri,
            obj_description(pg_class.oid, 'pg_class') AS table_comment
        FROM pg_catalog.pg_class JOIN z_asgard_admin.gestion_schema
                    ON relnamespace::regnamespace::text = quote_ident(nom_schema)
                LEFT JOIN geometry_columns ON f_table_schema = nom_schema AND f_table_name = relname
                LEFT JOIN index_niv1 ON coalesce(niv1, nom_schema) = niv1b
                LEFT JOIN index_niv2 ON coalesce(niv2, relname) = niv2b AND coalesce(niv1, nom_schema) = niv1bref
                LEFT JOIN z_asgard_admin.asgard_parametre ON True
        WHERE creation
            AND relkind IN ('r', 'v', 'm', 'f', 'p')
            AND has_table_privilege(pg_class.oid, 'SELECT')
            AND has_schema_privilege(relnamespace, 'USAGE')
) ;

------ 2.6 - VUE POUR ASGARDMENU ------

-- View: z_asgard.asgardmenu_metadata

CREATE OR REPLACE VIEW z_asgard.asgardmenu_metadata AS(
    SELECT
        gestion_schema.nom_schema,
        gestion_schema.bloc,
        gestion_schema.niv1,
        gestion_schema.niv2,
        pg_class.relname::text,
        pg_class.relkind::text,
        geometry_columns.type,
        geometry_columns.srid,
        geometry_columns.f_geometry_column,
        obj_description(pg_class.oid, 'pg_class') AS table_comment
    FROM pg_catalog.pg_class
        JOIN z_asgard_admin.gestion_schema
            ON relnamespace::regnamespace::text = quote_ident(nom_schema)
        LEFT JOIN geometry_columns
            ON f_table_schema = nom_schema AND f_table_name = relname
    WHERE creation
        AND relkind IN ('r', 'v', 'm', 'f', 'p')
        AND has_table_privilege(pg_class.oid, 'SELECT')
        AND has_schema_privilege(relnamespace, 'USAGE')
) ;

ALTER VIEW z_asgard.asgardmenu_metadata
    OWNER TO g_admin_ext ;
    
GRANT SELECT ON TABLE z_asgard.asgardmenu_metadata TO g_consult ;

COMMENT ON VIEW z_asgard.asgardmenu_metadata IS 'ASGARD. Données utiles à l''extension QGIS AsgardMenu. Elle contient une ligne par table ou assimilée et champ de géométrie.' ;
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
COMMENT ON COLUMN z_asgard.asgardmenu_metadata.relname IS 'Nom de la relation (table, vue, etc.).' ;
COMMENT ON COLUMN z_asgard.asgardmenu_metadata.relkind IS E'Type de relation :
r : table
v : vue
m : vue matérialisée
p : table partitionnée
f : table distante.' ;
COMMENT ON COLUMN z_asgard.asgardmenu_metadata.type IS 'Le cas échéant, type de géométrie.' ;
COMMENT ON COLUMN z_asgard.asgardmenu_metadata.srid IS 'Le cas échéant, identifiant du référentiel spatial.' ;
COMMENT ON COLUMN z_asgard.asgardmenu_metadata.f_geometry_column IS 'Le cas échéant, nom du champ de géométrie.' ;

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
        SELECT oid, unnest(typacl)::text AS acl
            FROM pg_catalog.pg_type
            WHERE typnamespace = n_schema
                AND typacl IS NOT NULL
                AND NOT n_role::oid = typowner
        )
        SELECT 'GRANT ' || privilege || ' ON TYPE ' || oid::regtype::text || ' TO %I'
            FROM t_acl, unnest(ARRAY['USAGE'], ARRAY['U']) AS l (privilege, prvlg)
            WHERE acl ~ ('^' || n_role_trans || '[=].*' || prvlg || '.*[/]') ;
    -- privilèges révoqués du propriétaire :
    RETURN QUERY
        WITH t_acl AS (
        SELECT oid, unnest(CASE WHEN typacl::text[] = ARRAY[]::text[]
                               OR NOT array_to_string(typacl, ',') ~ ('^' || n_role_trans || '[=]')
                                   AND NOT array_to_string(typacl, ',') ~ ('[,]' || n_role_trans || '[=]')
                           THEN ARRAY[NULL]::text[]
                           ELSE typacl::text[] END) AS acl
            FROM pg_catalog.pg_type
            WHERE typnamespace = n_schema
                AND n_role::oid = typowner
                AND typacl IS NOT NULL
        )
        SELECT 'REVOKE ' || privilege || ' ON TYPE ' || oid::regtype::text || ' FROM %I'
            FROM t_acl, unnest(ARRAY['USAGE'], ARRAY['U']) AS l (privilege, prvlg)
            WHERE (acl ~ ('^' || n_role_trans || '[=]')
                    AND NOT acl ~ ( '[=].*' || prvlg || '.*[/]')) OR acl IS NULL ;
END
$_$;


-- FUNCTION: z_asgard.asgard_synthese_public(regnamespace)

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
        WITH t_acl AS (
        SELECT unnest(nspacl)::text AS acl
            FROM pg_catalog.pg_namespace
            WHERE oid = n_schema::oid
                AND nspacl IS NOT NULL
        )
        SELECT 'GRANT ' || privilege || ' ON SCHEMA ' || n_schema::text || ' TO %I'
            FROM t_acl, unnest(ARRAY['USAGE', 'CREATE'], ARRAY['U', 'C']) AS l (privilege, prvlg)
            WHERE acl ~ ('^[=].*' || prvlg || '.*[/]') ;
    ------ TABLES ------
    -- inclut les vues, vues matérialisées, tables étrangères et partitions
    RETURN QUERY
        WITH t_acl AS (
        SELECT oid, unnest(relacl)::text AS acl
            FROM pg_catalog.pg_class
            WHERE relnamespace = n_schema
                AND relkind IN ('r', 'v', 'm', 'f', 'p')
                AND relacl IS NOT NULL
        )
        SELECT 'GRANT ' || privilege || ' ON TABLE ' || oid::regclass::text || ' TO %I'
            FROM t_acl, unnest(ARRAY['SELECT', 'INSERT', 'UPDATE', 'DELETE',
                                     'TRUNCATE', 'REFERENCES', 'TRIGGER'],
                               ARRAY['r', 'a', 'w', 'd', 'D', 'x', 't']) AS l (privilege, prvlg)
            WHERE acl ~ ('^[=].*' || prvlg || '.*[/]') ;
    ------ SEQUENCES ------
    RETURN QUERY
        WITH t_acl AS (
        SELECT oid, unnest(relacl)::text AS acl
            FROM pg_catalog.pg_class
            WHERE relnamespace = n_schema
                AND relkind = 'S'
                AND relacl IS NOT NULL
        )
        SELECT 'GRANT ' || privilege || ' ON SEQUENCE ' || oid::regclass::text || ' TO %I'
            FROM t_acl, unnest(ARRAY['SELECT', 'USAGE', 'UPDATE'],
                               ARRAY['r', 'U', 'w']) AS l (privilege, prvlg)
            WHERE acl ~ ('^[=].*' || prvlg || '.*[/]') ;
    ------ COLONNES ------
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
            WHERE acl ~ ('^[=].*' || prvlg || '.*[/]') ;
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
            SELECT oid, unnest(typacl)::text AS acl
                FROM pg_catalog.pg_type
                WHERE oid = obj_oid
                    AND typacl IS NOT NULL
                    AND NOT n_role::oid = typowner
            )
            SELECT 'GRANT ' || privilege || ' ON TYPE ' || oid::regtype::text || ' TO %I'
                FROM t_acl, unnest(ARRAY['USAGE'], ARRAY['U']) AS l (privilege, prvlg)
                WHERE acl ~ ('^' || n_role_trans || '[=].*' || prvlg || '.*[/]') ;
        -- privilèges révoqués du propriétaire (si n_role est le propriétaire de l'objet) :
        RETURN QUERY
            WITH t_acl AS (
            SELECT oid, unnest(CASE WHEN typacl::text[] = ARRAY[]::text[]
                                   OR NOT array_to_string(typacl, ',') ~ ('^' || n_role_trans || '[=]')
                                       AND NOT array_to_string(typacl, ',') ~ ('[,]' || n_role_trans || '[=]')
                               THEN ARRAY[NULL]::text[]
                               ELSE typacl::text[] END) AS acl
                FROM pg_catalog.pg_type
                WHERE oid = obj_oid
                    AND n_role::oid = typowner
                    AND typacl IS NOT NULL
            )
            SELECT 'REVOKE ' || privilege || ' ON TYPE ' || oid::regtype::text || ' FROM %I'
                FROM t_acl, unnest(ARRAY['USAGE'], ARRAY['U']) AS l (privilege, prvlg)
                WHERE (acl ~ ('^' || n_role_trans || '[=]')
                    AND NOT acl ~ ( '[=].*' || prvlg || '.*[/]')) OR acl IS NULL ;
    ELSE
       RAISE EXCEPTION 'FSR0. Le type d''objet % n''est pas pris en charge', obj_type ;
    END IF ;
END
$_$;

-- FUNCTION: z_asgard.asgard_synthese_public_obj(oid, text)

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
        -- privilèges attribués (si n_role n'est pas le propriétaire de l'objet) :
        RETURN QUERY
            WITH t_acl AS (
            SELECT oid, unnest(relacl)::text AS acl
                FROM pg_catalog.pg_class
                WHERE oid = obj_oid
                    AND relacl IS NOT NULL
            )
            SELECT 'GRANT ' || privilege || ' ON TABLE ' || oid::regclass::text || ' TO %I'
                FROM t_acl, unnest(ARRAY['SELECT', 'INSERT', 'UPDATE', 'DELETE',
                                         'TRUNCATE', 'REFERENCES', 'TRIGGER'],
                                   ARRAY['r', 'a', 'w', 'd', 'D', 'x', 't']) AS l (privilege, prvlg)
                WHERE acl ~ ('^[=].*' || prvlg || '.*[/]') ;
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
                WHERE acl ~ ('^[=].*' || prvlg || '.*[/]') ;
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
            )
            SELECT 'GRANT ' || privilege || ' ON SEQUENCE ' || oid::regclass::text || ' TO %I'
                FROM t_acl, unnest(ARRAY['SELECT', 'USAGE', 'UPDATE'],
                                   ARRAY['r', 'U', 'w']) AS l (privilege, prvlg)
                WHERE acl ~ ('^[=].*' || prvlg || '.*[/]') ;
    ELSE
       RAISE EXCEPTION 'FSP0. Le type d''objet % n''est pas pris en charge', obj_type ;
    END IF ;
END
$_$;

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
        
        GRANT SELECT ON TABLE z_asgard.qgis_menubuilder_metadata TO g_consult ;
        RAISE NOTICE '> GRANT SELECT ON TABLE z_asgard.qgis_menubuilder_metadata TO g_consult' ;
        
        GRANT SELECT ON TABLE z_asgard.asgardmenu_metadata TO g_consult ;
        RAISE NOTICE '> GRANT SELECT ON TABLE z_asgard.asgardmenu_metadata TO g_consult' ;
    
    ELSIF n_schema = 'z_asgard_admin'
    THEN
        -- rétablissement des droits de g_admin_ext
        RAISE NOTICE 'rétablissement des privilèges attendus pour g_admin_ext :' ;
        
        GRANT USAGE ON SCHEMA z_asgard_admin TO g_admin_ext ;
        RAISE NOTICE '> GRANT USAGE ON SCHEMA z_asgard_admin TO g_admin_ext' ;
        
        GRANT INSERT, SELECT, UPDATE, DELETE ON TABLE z_asgard_admin.gestion_schema TO g_admin_ext ;
        RAISE NOTICE '> GRANT INSERT, SELECT, UPDATE, DELETE ON TABLE z_asgard_admin.gestion_schema TO g_admin_ext' ;
        
        GRANT SELECT ON TABLE z_asgard_admin.asgard_parametre TO g_admin_ext ;
        RAISE NOTICE '> GRANT SELECT ON TABLE z_asgard_admin.asgard_parametre TO g_admin_ext' ;
        
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
                    THEN quote_literal(quote_ident(obj_schema) || '.' || quote_ident(obj_nom))
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
                    THEN quote_literal(quote_ident(obj_schema) || '.' || quote_ident(obj_nom))
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

------ 4.12 - IMPORT DE LA NOMENCLATURE DANS GESTION_SCHEMA ------

-- FUNCTION: z_asgard_admin.asgard_import_nomenclature(text[])

CREATE OR REPLACE FUNCTION z_asgard_admin.asgard_import_nomenclature(
                           domaines text[] default NULL::text[]
                           )
    RETURNS text
    LANGUAGE plpgsql
    AS $_$
/* OBJET : Fonction qui importe dans la table de gestion les schémas manquants
           de la nomenclature nationale - ou de certains domaines
           de la nomenclature nationale listés en argument - toujours avec
           creation valant False, même si le schéma existe (mais n'a pas été
           référencé).
           Des messages informent l'opérateur des schémas effectivement ajoutés.
           Lorsque le schéma est déjà référencé dans la table de gestion, réappliquer
           la fonction a pour effet de mettre à jour les champs relatifs à la
           nomenclature.
ARGUMENT : domaines (optionnel) : un tableau text[] contenant les noms des
domaines à importer, soit le "niveau 1"/niv1 ou niv1_abr des schémas. Si non renseigné,
toute la nomenclature est importée (hors schémas déjà référencés).
SORTIE : '__ FIN IMPORT NOMENCLATURE.' si la requête s'est exécutée normalement. */
DECLARE
    item record ;
    e_mssg text ;
    e_detl text ;
    e_hint text ;
BEGIN
    FOR item IN SELECT * FROM (
            VALUES
                ('c', true, 'Données génériques', 'donnees_generique', 'Découpage électoral', 'decoupage_electoral', 'c_don_gen_decoupage_electoral', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Données génériques', 'donnees_generique', 'Démographie', 'demographie', 'c_don_gen_demographie', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Données génériques', 'donnees_generique', 'Habillage des cartes', 'habillage', 'c_don_gen_habillage', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Données génériques', 'donnees_generique', 'Intercommunalité', 'intercommunalite', 'c_don_gen_intercommunalite', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Données génériques', 'donnees_generique', 'Milieu physique', 'milieu_physique', 'c_don_gen_milieu_physique', false, 'g_admin', NULL, 'g_consult'),
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
                ('c', true, 'Air & climat', 'air_climat', 'Qualité de l’air & pollution', 'qualité_pollution', 'c_air_clim_qual_polu', false, 'g_admin', NULL, 'g_consult'),
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
                ('c', true, 'Données génériques', 'donnees_generique', 'Action publique', 'action_publique', 'c_don_gen_action_publique', false, 'g_admin', NULL, 'g_consult'),
                ('c', true, 'Données génériques', 'donnees_generique', 'Découpage administratif', 'administratif', 'c_don_gen_administratif', false, 'g_admin', NULL, 'g_consult'),
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
                            e_detl = PG_EXCEPTION_DETAIL ;
    RAISE EXCEPTION 'FIN0 > %', e_mssg
        USING DETAIL = e_detl,
            HINT = e_hint ;
    

END
$_$;

------ 4.13 - REAFFECTATION DES PRIVILEGES D'UN RÔLE ------

-- FUNCTION: z_asgard_admin.asgard_reaffecte_role(text, text, boolean, boolean, boolean)

CREATE OR REPLACE FUNCTION z_asgard_admin.asgard_reaffecte_role(
                                n_role text,
                                n_role_cible text DEFAULT NULL,
                                b_hors_asgard boolean DEFAULT False,
                                b_privileges boolean DEFAULT True,
                                b_default_acl boolean DEFAULT FALSE
                                )
    RETURNS text
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
SORTIE : '__ REAFFECTATION REUSSIE' si la fonction s'est exécutée sans
erreur. */
DECLARE
    item record ;
    n_producteur_cible text := coalesce(n_role_cible, 'g_admin') ;
    c record ;
    k int ;
    utilisateur text ;
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

    RETURN '__ REAFFECTATION REUSSIE' ;
END
$_$;

------ 4.16 - DIAGNOSTIC DES DROITS NON STANDARDS ------

-- FUNCTION: z_asgard_admin.asgard_diagnostic()

CREATE OR REPLACE FUNCTION z_asgard_admin.asgard_diagnostic()
    RETURNS TABLE (nom_schema text, nom_objet text, typ_objet text, critique boolean, anomalie text)
    LANGUAGE plpgsql
    AS $_$
/* OBJET : Pour tous les schémas référencés par ASGARD et
           existants dans la base, asgard_diagnostic liste
           les écarts avec les droits standards.
ARGUMENT : néant.
APPEL : SELECT * FROM z_asgard_admin.asgard_diagnostic() ;
SORTIE : une table avec quatre attributs,
    - nom_schema = nom du schéma ;
    - nom_objet = nom de l'objet concerné ;
    - typ_objet = le type d'objet ;
    - critique = True si l'anomalie est problématique pour le
      bon fonctionnement d'ASGARD, False si elle est bénigne.
    - anomalie = description de l'anomalie. */
DECLARE
    item record ;
    catalogue record ;
    objet record ;
    asgard record ;
BEGIN

    FOR item IN (
        SELECT
            gestion_schema_etr.nom_schema,
            gestion_schema_etr.oid_schema,
            r1.rolname AS producteur,
            r1.oid AS oid_producteur,
            CASE WHEN editeur = 'public' THEN 'public' ELSE r2.rolname END AS editeur,
            r2.oid AS oid_editeur,
            CASE WHEN lecteur = 'public' THEN 'public' ELSE r3.rolname END AS lecteur,
            r3.oid AS oid_lecteur
            FROM z_asgard.gestion_schema_etr
                LEFT JOIN pg_catalog.pg_roles AS r1 ON r1.oid = oid_producteur
                LEFT JOIN pg_catalog.pg_roles AS r2 ON r2.oid = oid_editeur
                LEFT JOIN pg_catalog.pg_roles AS r3 ON r3.oid = oid_lecteur
            WHERE gestion_schema_etr.creation
            )
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
                            CASE WHEN catalogue.catalogue = 'pg_default_acl' THEN ''
                                WHEN catalogue.catalogue = 'pg_attribute'
                                    THEN '(parse_ident(attrelid::regclass::text))[2] || '' ('' || ' || catalogue.prefixe || 'name || '')'' AS objname, '
                                ELSE catalogue.prefixe || 'name::text AS objname, ' END || '
                            regexp_replace(' || CASE WHEN catalogue.catalogue = 'pg_default_acl' THEN 'defaclrole'
                                WHEN catalogue.catalogue = 'pg_attribute' THEN 'NULL'
                                ELSE  catalogue.prefixe || 'owner' END || '::regrole::text, ''^["]?(.*?)["]?$'', ''\1'') AS objowner' ||
                            CASE WHEN catalogue.droits THEN ', ' || catalogue.prefixe || 'acl AS objacl' ELSE '' END || '
                            FROM pg_catalog.' || catalogue.catalogue || '
                            WHERE ' || CASE WHEN catalogue.catalogue = 'pg_attribute'
                                        THEN '(parse_ident(attrelid::regclass::text))[2] IS NOT NULL' ||
                                        -- la condition "(parse_ident(attrelid::regclass::text))[2] IS NOT NULL" exclut de fait les attributs
                                        -- des tables des schéma public et pg_catalog, dans l'hypothèse où ceux-ci auraient pu être référencés
                                            ' AND quote_ident((parse_ident(attrelid::regclass::text))[1])::regnamespace::oid = ' || item.oid_schema::text
                                    WHEN catalogue.catalogue = 'pg_namespace' THEN catalogue.prefixe || 'name = ' || quote_literal(item.nom_schema)
                                    ELSE catalogue.prefixe || 'namespace = ' || item.oid_schema::text END ||
                                CASE WHEN catalogue.attrib_genre IS NOT NULL
                                    THEN ' AND ' || catalogue.attrib_genre || ' ~ ' || quote_literal(catalogue.valeur_genre)
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
                                        LEFT JOIN a ON a.acl ~ ('[=][rawdDxtUCX]*' || p.prvlg)
                                    WHERE a.acl IS NOT NULL
                            )
                            SELECT
                                item.nom_schema::text,
                                NULL,
                                'privilège par défaut',
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
                                    ('z_asgard_admin', 'asgard_parametre', 'table', 'g_admin_ext', 'r'),
                                    ('z_asgard', 'z_asgard', 'schéma', 'g_consult', 'U'),
                                    ('z_asgard', 'gestion_schema_usr', 'vue', 'g_consult', 'r'),
                                    ('z_asgard', 'gestion_schema_etr', 'vue', 'g_consult', 'r'),
                                    ('z_asgard', 'qgis_menubuilder_metadata', 'vue', 'g_consult', 'r'),
                                    ('z_asgard', 'asgardmenu_metadata', 'vue', 'g_consult', 'r')
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
                                        LEFT JOIN a1 ON a1.acl ~ ('[=][rawdDxtUCX]*' || p.prvlg)
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
                                WHERE a2.prvlg IS NULL OR b.prvlg IS NULL ;
                    END IF ;
                END LOOP ;
            END IF ;
        END LOOP ;        
    END LOOP ;
END
$_$;

ALTER FUNCTION z_asgard_admin.asgard_diagnostic()
    OWNER TO g_admin ;

COMMENT ON FUNCTION z_asgard_admin.asgard_diagnostic() IS 'ASGARD. Fonction qui liste les écarts vis-à-vis des droits standards sur les schémas actifs référencés par ASGARD.' ;


-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

---------------------------------------------
------ 5 - TRIGGERS SUR GESTION_SCHEMA ------
---------------------------------------------   


------ 5.1 - TRIGGER BEFORE ------

-- FUNCTION: z_asgard_admin.asgard_on_modify_gestion_schema_before()

CREATE OR REPLACE FUNCTION z_asgard_admin.asgard_on_modify_gestion_schema_before() RETURNS trigger
    LANGUAGE plpgsql
    AS $BODY$
/* OBJET : Fonction exécutée par le trigger asgard_on_modify_gestion_schema_before,
           qui valide les informations saisies dans la table de gestion.
CIBLES : z_asgard_admin.gestion_schema.
PORTEE : FOR EACH ROW.
DECLENCHEMENT : BEFORE INSERT, UPDATE, DELETE.*/
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
                    USING DETAIL = 'Seul les membres du rôle producteur ' || OLD.oid_producteur::regrole::text || ' peuvent supprimer ce schéma.' ;
            ELSE
                EXECUTE 'DROP SCHEMA ' || quote_ident(OLD.nom_schema) || ' CASCADE' ;
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
            OR NOT NEW.ctrl[1] IN ('CREATE', 'RENAME', 'OWNER', 'DROP', 'SELF', 'EXIT')
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
        -- les remontées du trigger AFTER (SELF)
        -- sont exclues, car les contraintes ont déjà
        -- été validées (et pose problèmes avec les
        -- contrôles d'OID sur les UPDATE, car ceux-ci
        -- ne seront pas nécessairement déjà remplis) ;
        -- les requêtes EXIT de même, car c'est un
        -- pré-requis à la suppression qui ne fait
        -- que modifier le champ ctrl
        IF NEW.ctrl[1] IN ('SELF', 'EXIT')
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
                    SELECT replace(nspowner::regrole::text, '"', ''), nspowner
                        INTO NEW.producteur, NEW.oid_producteur
                        FROM pg_catalog.pg_namespace
                        WHERE pg_namespace.oid = NEW.oid_schema ;
                    RAISE NOTICE '[table de gestion] ANOMALIE. Schéma %. L''OID actuellement renseigné pour le producteur est invalide. Poursuite avec l''OID du propriétaire courant du schéma.', NEW.nom_schema ;
                    NEW.ctrl := array_append(NEW.ctrl, 'CLEAN producteur') ;
                ELSIF NOT n_role = NEW.producteur
                -- libellé obsolète du producteur
                THEN
                    NEW.producteur := n_role ;
                    RAISE NOTICE '[table de gestion] Schéma %. Mise à jour du libellé du rôle producteur, renommé entre temps.', NEW.nom_schema
                        USING DETAIL = 'Ancien nom "' || OLD.producteur || '", nouveau nom "' || NEW.producteur || '".' ;
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
                        USING DETAIL = 'Ancien nom "' || OLD.editeur || '".' ;
                    NEW.ctrl := array_append(NEW.ctrl, 'CLEAN editeur') ;
                ELSIF NOT n_role = NEW.editeur
                -- libellé obsolète de l'éditeur
                THEN
                    NEW.editeur := n_role ;
                    RAISE NOTICE '[table de gestion] Schéma %. Mise à jour du libellé du rôle éditeur, renommé entre temps.', NEW.nom_schema
                        USING DETAIL = 'Ancien nom "' || OLD.editeur || '", nouveau nom "' || NEW.editeur || '".' ;
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
                        USING DETAIL = 'Ancien nom "' || OLD.lecteur || '".' ;
                    NEW.ctrl := array_append(NEW.ctrl, 'CLEAN lecteur') ;
                ELSIF NOT n_role = NEW.lecteur
                -- libellé obsolète du lecteur
                THEN
                    NEW.lecteur := n_role ;
                    RAISE NOTICE '[table de gestion] Schéma %. Mise à jour du libellé du rôle lecteur, renommé entre temps.', NEW.nom_schema
                        USING DETAIL = 'Ancien nom "' || OLD.lecteur || '", nouveau nom "' || NEW.lecteur || '".' ;
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
                    RAISE NOTICE '[table de gestion] Mise à jour du bloc pour le schéma %.', NEW.nom_schema || ' (' || NEW.bloc || ')' ;
                    
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
                    RAISE NOTICE '[table de gestion] Restauration du préfixe du schéma %.', NEW.nom_schema || ' d''après son ancien bloc (' || OLD.bloc || ')' ;
                    -- on ne reprend pas l'ancien nom au cas où autre chose que le préfixe aurait été
                    -- changé.
                    
                ELSIF NEW.bloc IS NULL AND NOT OLD.bloc = 'd'
                -- mise à la corbeille via le nom avec mise à NULL du bloc en
                -- parallèle + s'il y a un ancien bloc récupérable
                THEN
                    NEW.nom_schema := regexp_replace(NEW.nom_schema, '^(d)_', OLD.bloc || '_') ;
                    RAISE NOTICE '[table de gestion] Restauration du préfixe du schéma %.', NEW.nom_schema || ' d''après son ancien bloc (' || OLD.bloc || ')' ;
                
                    NEW.bloc := 'd' ;
                    RAISE NOTICE '[table de gestion] Mise à jour du bloc pour le schéma %.', NEW.nom_schema || ' (' || NEW.bloc || ')' ;
                    
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
                    RAISE NOTICE '[table de gestion] Mise à jour du bloc pour le schéma %.', NEW.nom_schema || ' (' || NEW.bloc || ')' ;
                    
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
                    RAISE NOTICE '[table de gestion] Restauration du préfixe du schéma %.', NEW.nom_schema || ' d''après son ancien bloc (' || OLD.bloc || ')' ;
                    
                    NEW.bloc := 'd' ;
                    RAISE NOTICE '[table de gestion] Mise à jour du bloc pour le schéma %.', NEW.nom_schema || ' (' || NEW.bloc || ')' ;   
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
                    RAISE NOTICE '[table de gestion] Mise à jour du bloc pour le schéma %.', NEW.nom_schema || ' (' || NEW.bloc || ')' ;
                END IF ;
            ELSE
                -- sur un INSERT,
                -- on met le préfixe du nom du schéma dans bloc
                NEW.bloc := substring(NEW.nom_schema, '^([a-z])_') ;
                RAISE NOTICE '[table de gestion] Mise à jour du bloc pour le schéma %.', NEW.nom_schema || ' (' || NEW.bloc || ')' ;
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
                        RAISE NOTICE '[table de gestion] Mise à jour du bloc pour le schéma %.', NEW.nom_schema || ' (' || NEW.bloc || ')' ;
                    ELSIF NOT NEW.bloc ~ '^[a-z]$'
                    -- si le nouveau bloc est invalide, on renvoie une erreur
                    THEN
                        RAISE EXCEPTION 'TB14. Saisie invalide (schéma %). Le bloc doit être une lettre minuscule ou rien.', NEW.nom_schema ;
                    ELSE
                    -- si le bloc est valide, on met à jour le préfixe du schéma d'après le bloc
                        NEW.nom_schema := regexp_replace(NEW.nom_schema, '^([a-z])?_', NEW.bloc || '_') ;
                        RAISE NOTICE '[table de gestion] Mise à jour du préfixe du schéma %.', NEW.nom_schema || ' d''après son bloc (' || NEW.bloc || ')' ;
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
                    RAISE NOTICE '[table de gestion] Mise à jour du préfixe du schéma %.', NEW.nom_schema || ' d''après son bloc (' || NEW.bloc || ')' ;
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
                    RAISE NOTICE '[table de gestion] Mise à jour du préfixe du schéma %.', NEW.nom_schema || ' d''après son bloc (' || NEW.bloc || ')' ;
                END IF ;
            ELSE
            -- sur un INSERT, préfixage du schéma selon le bloc
                NEW.nom_schema := NEW.bloc || '_' || NEW.nom_schema ;
                RAISE NOTICE '[table de gestion] Mise à jour du préfixe du schéma %.', NEW.nom_schema || ' d''après son bloc (' || NEW.bloc || ')' ;
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
                    USING DETAIL = 'Seul le rôle producteur ' || OLD.producteur || ' (super-utilisateur) peut modifier ce schéma.' ;
            END IF ;
        END IF ;
        
        IF NEW.creation
            AND NOT OLD.creation
            AND NEW.producteur IN (SELECT rolname FROM pg_catalog.pg_roles WHERE rolsuper)
        THEN
            IF NOT pg_has_role(NEW.producteur, 'USAGE')
            THEN
                RAISE EXCEPTION 'TB21. Opération interdite (schéma %).', NEW.nom_schema
                    USING DETAIL = 'Seul le super-utilisateur ' || NEW.producteur || ' peut créer un schéma dont il est identifié comme producteur.' ;
            END IF ;
        END IF ;
        
        IF NEW.producteur IN (SELECT rolname FROM pg_catalog.pg_roles WHERE rolsuper)
            AND NEW.creation
            AND NOT OLD.producteur = NEW.producteur AND (NEW.ctrl IS NULL OR NOT 'CLEAN producteur' = ANY(array_remove(NEW.ctrl, NULL)))
        THEN
            IF NOT pg_has_role(NEW.producteur, 'USAGE')
            THEN
                RAISE EXCEPTION 'TB24. Opération interdite (schéma %).', NEW.nom_schema
                    USING DETAIL = 'Seul le super-utilisateur ' || NEW.producteur || ' peut se désigner comme producteur d''un schéma.' ;
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
                    USING DETAIL = 'Seul le super-utilisateur ' || NEW.producteur || ' peut créer un schéma dont il est identifié comme producteur.' ;
            END IF ;
        END IF ;            
        
        IF NEW.producteur IN (SELECT rolname FROM pg_catalog.pg_roles WHERE rolsuper)
                AND NEW.nom_schema IN (SELECT nspname FROM pg_catalog.pg_namespace)
                -- schéma pré-existant en cours de référencement
        THEN
            IF NOT pg_has_role(NEW.producteur, 'USAGE') 
            THEN
                RAISE EXCEPTION 'TB25. Opération interdite (schéma %).', NEW.nom_schema
                    USING DETAIL = 'Seul le super-utilisateur ' || NEW.producteur || ' peut référencer dans ASGARD un schéma dont il est identifié comme producteur.' ;
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


-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -