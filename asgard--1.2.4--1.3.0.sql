\echo Use "CREATE EXTENSION asgard" to load this file. \quit
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
--
-- ASGARD - Système de gestion des droits pour PostgreSQL, version 1.3.0
-- > Script de mise à jour depuis la version 1.2.4.
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
-- https://snum.scenari-community.org/Asgard/Documentation/#SEC_1-3-0
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


----------------------------------------
------ 2 - PREPARATION DES OBJETS ------
----------------------------------------
/* 2.8 - VERSION LECTURE SEULE DE GESTION_SCHEMA_USR */

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
    
GRANT SELECT ON TABLE z_asgard.gestion_schema_read_only TO g_consult ;

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
------ 4 - FONCTIONS UTILITAIRES ------
---------------------------------------    
/* 4.8 - REINITIALISATION DES PRIVILEGES SUR UN SCHEMA
   4.12 - IMPORT DE LA NOMENCLATURE DANS GESTION_SCHEMA
   4.16 - DIAGNOSTIC DES DROITS NON STANDARDS */

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

ALTER FUNCTION z_asgard.asgard_initialise_schema(text, boolean, boolean)
    OWNER TO g_admin_ext ;

COMMENT ON FUNCTION z_asgard.asgard_initialise_schema(text, boolean, boolean) IS 'ASGARD. Fonction qui réinitialise les privilèges sur un schéma (et l''ajoute à la table de gestion s''il n''y est pas déjà).' ;


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
                            e_detl = PG_EXCEPTION_DETAIL ;
    RAISE EXCEPTION 'FIN0 > %', e_mssg
        USING DETAIL = e_detl,
            HINT = e_hint ;
    

END
$_$;

ALTER FUNCTION z_asgard_admin.asgard_import_nomenclature(text[])
    OWNER TO g_admin ;

COMMENT ON FUNCTION z_asgard_admin.asgard_import_nomenclature(text[]) IS 'ASGARD. Fonction qui importe dans la table de gestion les schémas manquants de la nomenclature nationale - ou de certains domaines de la nomenclature nationale listés en argument.' ;


-- rétro-activité des modification de la nomenclature :

UPDATE z_asgard.gestion_schema_usr
    SET nom_schema = 'c_air_clim_qual_pollu',
        niv2_abr = 'qualite_pollution'
    WHERE nom_schema = 'c_air_clim_qual_polu' ;

UPDATE z_asgard.gestion_schema_usr
    SET niv1_abr = 'donnee_generique'
    WHERE niv1_abr = 'donnees_generique' ;


------ 4.16 - DIAGNOSTIC DES DROITS NON STANDARDS ------

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
                                    ('z_asgard', 'asgardmanager_metadata', 'vue', 'g_consult', 'r'),
                                    ('z_asgard', 'gestion_schema_read_only', 'vue', 'g_consult', 'r')
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


-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


-----------------------------------------------------------
------ 6 - GESTION DES PERMISSIONS SUR LAYER_STYLES ------
-----------------------------------------------------------
/* 6.1 - PETITES FONCTIONS UTILITAIRES
   6.2 - FONCTION D'ADMINISTRATION DES PERMISSIONS SUR LAYER_STYLES */

------ 6.1 - PETITES FONCTIONS UTILITAIRES ------

-- FUNCTION: z_asgard.asgard_has_role_usage(text, text)

CREATE OR REPLACE FUNCTION z_asgard.asgard_has_role_usage(role_parent text, role_enfant text DEFAULT current_user)
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
/* OBJET : Cette fonction détermine si un rôle est membre d'un autre (
           y compris indirectement) et hérite de ses droits. Elle est
           équivalente à pg_has_role(role_enfant, role_parent, 'USAGE')
           en plus permissif - elle renvoie False quand l'un des rôles
           n'existe pas plutôt que d'échouer.
ARGUMENTS :
- role_parent est le nom du rôle dont on souhaite savoir si l'autre
est membre ;
- (optionnel) role_enfant est le nom du rôle dont on souhaite savoir
s'il est membre de l'autre. Si non renseigné, la fonction testera
l'utilisateur courant.
SORTIE : True si la relation entre les rôles est vérifiée. False
si elle ne l'est pas ou si l'un des rôles n'existe pas. */
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


-- FUNCTION: z_asgard.asgard_is_relation_owner(text, text, text)

CREATE OR REPLACE FUNCTION z_asgard.asgard_is_relation_owner(
        nom_schema text,
        nom_relation text,
        nom_role text DEFAULT current_user
        )
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
/* OBJET : Cette fonction détermine si un rôle est membre du
           propriétaire d'une table, vue ou autre relation.
ARGUMENTS :
- nom_schema est une chaîne de caractères correspondant au nom
du schéma contenant la relation ;
- nom_relation est une chaîne de caractères correspondant au nom
de la relation ;
- (optionnel) nom_role est le nom du rôle dont on veut vérifier
les permissions. Si non renseigné, la fonction testera
l'utilisateur courant.
Tous les arguments sont en écriture naturelle, sans les
guillemets des identifiants PostgreSQL.
SORTIE : True si le rôle est membre du propriétaire de la relation.
False sinon, incluant les cas où le rôle ou la relation n'existe
pas. */
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

COMMENT ON FUNCTION z_asgard.asgard_is_relation_owner(text, text, text) IS 'ASGARD. Le rôle est-il membre du propriétaire de la relation considérée ?' ;


-- FUNCTION: z_asgard.asgard_is_producteur(text, text)

CREATE OR REPLACE FUNCTION z_asgard.asgard_is_producteur(
        schema_cible text,
        nom_role text DEFAULT current_user
        )
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
/* OBJET : Cette fonction détermine si le rôle considéré est membre
           du rôle producteur d'un schéma donné.
ARGUMENTS :
- nom_schema est une chaîne de caractères correspondant à un
nom de schéma ;
- (optionnel) nom_role est le nom du rôle dont on veut vérifier
les permissions. Si non renseigné, la fonction testera
l'utilisateur courant.
Tous les arguments sont en écriture naturelle, sans les
guillemets des identifiants PostgreSQL.
SORTIE : True si le rôle est membre du rôle producteur du schéma.
False si le schéma n'existe pas ou si le rôle n'est pas membre de
son producteur. */
DECLARE
    producteur text ;
BEGIN
    
    SELECT gestion_schema_read_only.producteur INTO producteur
        FROM z_asgard.gestion_schema_read_only
        WHERE gestion_schema_read_only.nom_schema = schema_cible ;
        
    IF NOT FOUND
    THEN
        RETURN False ;
    END IF ;
    
    RETURN z_asgard.asgard_has_role_usage(producteur, nom_role) ;
    
END
$_$;

ALTER FUNCTION z_asgard.asgard_is_producteur(text, text)
    OWNER TO g_admin_ext ;

COMMENT ON FUNCTION z_asgard.asgard_is_producteur(text, text) IS 'ASGARD. Le rôle est-il membre du producteur du schéma considéré ?' ;


-- FUNCTION: z_asgard.asgard_is_editeur(text, text)

CREATE OR REPLACE FUNCTION z_asgard.asgard_is_editeur(
        schema_cible text,
        nom_role text DEFAULT current_user
        )
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
/* OBJET : Cette fonction détermine si le rôle considéré est membre
           du rôle éditeur d'un schéma donné.
ARGUMENTS :
- nom_schema est une chaîne de caractères correspondant à un
nom de schéma ;
- (optionnel) nom_role est le nom du rôle dont on veut vérifier
les permissions. Si non renseigné, la fonction testera
l'utilisateur courant.
Tous les arguments sont en écriture naturelle, sans les
guillemets des identifiants PostgreSQL.
SORTIE : True si le rôle est membre du rôle editeur du schéma.
False si le schéma n'existe pas ou si le rôle n'est pas membre de
son éditeur. */
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

COMMENT ON FUNCTION z_asgard.asgard_is_editeur(text, text) IS 'ASGARD. Le rôle est-il membre du éditeur du schéma considéré ?' ;


-- FUNCTION: z_asgard.asgard_is_lecteur(text, text)

CREATE OR REPLACE FUNCTION z_asgard.asgard_is_lecteur(
        schema_cible text,
        nom_role text DEFAULT current_user
        )
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
/* OBJET : Cette fonction détermine si le rôle considéré est membre
           du rôle lecteur d'un schéma donné.
ARGUMENTS :
- nom_schema est une chaîne de caractères correspondant à un
nom de schéma ;
- (optionnel) nom_role est le nom du rôle dont on veut vérifier
les permissions. Si non renseigné, la fonction testera
l'utilisateur courant.
Tous les arguments sont en écriture naturelle, sans les
guillemets des identifiants PostgreSQL.
SORTIE : True si le rôle est membre du rôle lecteur du schéma.
False si le schéma n'existe pas ou si le rôle n'est pas membre de
son lecteur. */
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

COMMENT ON FUNCTION z_asgard.asgard_is_lecteur(text, text) IS 'ASGARD. Le rôle est-il membre du lecteur du schéma considéré ?' ;


------ 6.2 - FONCTION D'ADMINISTRATION DES PERMISSIONS SUR LAYER_STYLES ------

-- FUNCTION: z_asgard_admin.asgard_layer_styles(int)

CREATE OR REPLACE FUNCTION z_asgard_admin.asgard_layer_styles(variante int)
    RETURNS text
    LANGUAGE plpgsql
    AS $_$
/* OBJET : Cette fonction confère à g_consult un accès en
           lecture à la table layer_styles du schéma public (table créée
           par QGIS pour stocker les styles de couches), ainsi que des
           droits d'écriture selon la stratégie spécifiée par le paramètre
           "variante".
           Elle échoue si la table layer_styles n'existe pas.
           Il est possible de relancer la fonction à volonté pour
           modifier la stratégie à mettre en oeuvre.
           Hormis pour la variante 0, la fonction a pour effet d'activer
           la sécurisation niveau ligne sur la table, ce qui pourra
           rendre inopérants des accès précédemment définis.
           
ARGUMENT : variante est un entier spécifiant les droits à donner en écriture.
    - 0 : autorise g_admin à modifier layer_styles. À noter que cette option
    n'a d'intérêt que si g_admin n'est pas propriétaire de la table layer_styles ;
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
    
SORTIE : '__ FIN ATTRIBUTION PERMISSIONS.' (ou '__ FIN SUPPRESSION PERMISSIONS.'
pour la variante 99) si l'opération s'est déroulée comme prévu. */

BEGIN

    IF NOT 'layer_styles' IN (SELECT relname FROM pg_catalog.pg_class WHERE relnamespace = 'public'::regnamespace)
    THEN
        RAISE EXCEPTION 'ALS01. La table layer_styles n''existe pas.'
            USING ERRCODE = '42P01' ;
    END IF ;
    
    IF NOT z_asgard.asgard_is_relation_owner('public', 'layer_styles')
    THEN
        RAISE EXCEPTION 'ALS02. Vous devez être membre du rôle propriétaire de la table layer_styles pour réaliser cette opération.'
            USING ERRCODE = '42501' ;
    END IF ;

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
    DROP POLICY IF EXISTS layer_styles_g_consult_select ON layer_styles ;
    DROP POLICY IF EXISTS layer_styles_producteur_insert ON layer_styles ;
    DROP POLICY IF EXISTS layer_styles_producteur_update ON layer_styles ;
    DROP POLICY IF EXISTS layer_styles_producteur_delete ON layer_styles ;
    DROP POLICY IF EXISTS layer_styles_editeur_insert ON layer_styles ;
    DROP POLICY IF EXISTS layer_styles_editeur_update ON layer_styles ;
    DROP POLICY IF EXISTS layer_styles_editeur_delete ON layer_styles ;
    DROP POLICY IF EXISTS layer_styles_lecteur_insert ON layer_styles ;
    DROP POLICY IF EXISTS layer_styles_lecteur_update ON layer_styles ;
    DROP POLICY IF EXISTS layer_styles_lecteur_delete ON layer_styles ;
    
    -- désactivation de la sécurisation niveau ligne
    ALTER TABLE layer_styles DISABLE ROW LEVEL SECURITY ;
    
    IF variante = 99
    THEN
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

    RETURN '__ FIN ATTRIBUTION PERMISSIONS.' ;
END
$_$;

ALTER FUNCTION z_asgard_admin.asgard_layer_styles(int)
    OWNER TO g_admin ;

COMMENT ON FUNCTION z_asgard_admin.asgard_layer_styles(int) IS 'ASGARD. Fonction qui définit des permissions sur la table layer_styles de QGIS.' ;

-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
