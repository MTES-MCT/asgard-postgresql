\echo Use "CREATE EXTENSION asgard" to load this file. \quit
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
--
-- ASGARD - Système de gestion des droits pour PostgreSQL, version 1.2.4
-- > Script de mise à jour depuis la version 1.2.2.
--
-- Copyright République Française, 2020-2021.
-- Secrétariat général du Ministère de la transition écologique, du
-- Ministère de la cohésion des territoires et des relations avec les
-- collectivités territoriales et du Ministère de la Mer.
-- Service du numérique.
--
-- contributeurs pour cette version : Leslie Lemaire (SNUM/UNI/DRC).
-- 
-- mél : drc.uni.snum.sg@developpement-durable.gouv.fr
--
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
--
-- Note de version :
-- https://snum.scenari-community.org/Asgard/Documentation/#SEC_1-2-4
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


---------------------------------------
------ 1 - PREPARATION DES ROLES ------
---------------------------------------

ALTER ROLE g_admin NOREPLICATION BYPASSRLS ;


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
            SELECT attname::text INTO xowner
                FROM pg_catalog.pg_attribute
                WHERE attrelid = obj.classid AND attname ~ 'owner' ;
                -- pourrait ne rien renvoyer pour certains pseudo-objets
                -- comme les "table constraint"
                
            IF FOUND
            THEN
                
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
                        ELSE
                            RAISE WARNING'Le producteur du schéma de la vue % ne dispose pas des droits nécessaires pour accéder à ses données sources.',
                                    CASE WHEN obj.object_type = 'materialized view' THEN 'matérialisée ' ELSE '' END || obj.object_identity
                                USING DETAIL = src.liblg || ' source ' || src.relnamespace::regnamespace::text || '.' || src.relname::text
                                        || ', propriétaire ' || src.relowner::regrole::text  || '.' ;
                        END IF ;
                    END LOOP ;            
                END IF ;
                
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


------ 3.5 - EVENT TRIGGER SUR ALTER OBJET ------

-- FUNCTION: z_asgard_admin.asgard_on_alter_objet()

CREATE OR REPLACE FUNCTION z_asgard_admin.asgard_on_alter_objet() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $BODY$
/* OBJET : Fonction exécutée par l'event trigger asgard_on_alter_objet, qui
           assure que le propriétaire de l'objet reste le propriétaire du
           schéma qui le contient après l'exécution d'une commande ALTER.
           Elle vise en particulier les SET SCHEMA (lorsque le schéma
           cible a un producteur différent de celui du schéma d'origine, elle
           modifie le propriétaire de l'objet en conséquence) et les 
           OWNER TO (elle inhibe leur effet en rendant la propriété de
           l'objet au producteur du schéma).
           Elle n'agit pas sur les privilèges.
AVERTISSEMENT : Les commandes ALTER OPERATOR CLASS, ALTER OPERATOR FAMILY
et ALTER STATISTICS ne sont pas pris en charge pour l'heure.
DECLENCHEMENT : ON DDL COMMAND END.
CONDITION : WHEN TAG IN ('ALTER TABLE', 'ALTER VIEW',
'ALTER MATERIALIZED VIEW', 'ALTER SEQUENCE', 'ALTER FOREIGN TABLE',
'ALTER FUNCTION', 'ALTER OPERATOR', 'ALTER AGGREGATE', 'ALTER COLLATION',
'ALTER CONVERSION', 'ALTER DOMAIN', 'ALTER TEXT SEARCH CONFIGURATION',
'ALTER TEXT SEARCH DICTIONARY', 'ALTER TYPE') */
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
        RAISE EXCEPTION 'EAO1. Vous devez être membre du groupe lecteur du schéma z_asgard pour réaliser cette opération.' ;
    END IF ;
    
    IF NOT has_table_privilege('z_asgard.gestion_schema_etr', 'SELECT')
    THEN
        RAISE EXCEPTION 'EAO2. Vous devez être membre du groupe lecteur du schéma z_asgard pour réaliser cette opération.' ;
    END IF ;

    FOR obj IN SELECT DISTINCT classid, objid, object_type, schema_name, object_identity
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
                EXECUTE 'SELECT ' || xowner || '::regrole FROM ' ||
                    obj.classid::regclass::text || ' WHERE oid = ' || obj.objid::text
                    INTO STRICT a_producteur ;
                       
                -- si les deux rôles sont différents
                IF NOT n_producteur = a_producteur
                THEN 
                    ------ MODIFICATION DU PROPRIETAIRE ------
                    -- l'objet est attribué au propriétaire désigné pour le schéma
                    -- (n_producteur)
                    RAISE NOTICE 'attribution de la propriété de % au rôle producteur du schéma :', replace(obj.object_identity, '"', '') ;
                    l := 'ALTER ' || obj.object_type || ' ' || obj.object_identity ||
                        ' OWNER TO '  || n_producteur::text ;  
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
$BODY$;
