\echo Use "CREATE EXTENSION asgard" to load this file. \quit
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
--
-- ASGARD - Système de gestion des droits pour PostgreSQL, version 1.3.1
-- > Script de mise à jour depuis la version 1.3.0.
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
-- https://snum.scenari-community.org/Asgard/Documentation/#SEC_1-3-1
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


-----------------------------------------------------------
------ 6 - GESTION DES PERMISSIONS SUR LAYER_STYLES ------
-----------------------------------------------------------
/* 6.2 - FONCTION D'ADMINISTRATION DES PERMISSIONS SUR LAYER_STYLES */


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
