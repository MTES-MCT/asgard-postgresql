\echo Use "ALTER EXTENSION plume_pg UPDATE TO '1.4.1'" to load this file. \quit
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
--
-- ASGARD - Système de gestion des droits pour PostgreSQL, version 1.4.1
-- > Script de mise à jour depuis la version 1.4.0
--
-- Copyright République Française, 2020-2024.
-- Secrétariat général du Ministère de la Transition écologique et
-- de la Cohésion des territoires.
-- Direction du Numérique.
--
-- contributrice pour cette version : Leslie Lemaire (DNUM/UNI/DRC).
-- 
-- mél : drc.uni.dnum.sg@developpement-durable.gouv.fr
--
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
--
-- Note de version :
-- https://snum.scenari-community.org/Asgard/Documentation/co/SEC_1-4-1.html
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
-- Elle n'est pas compatible avec les versions 9.4 ou antérieures de
-- PostgreSQL.
--
-- schémas contenant les objets : z_asgard et z_asgard_admin.
--
-- objets créés par le script :
-- - Function: z_asgard_admin.asgard_nettoyage_oids()
-- - Function: z_asgard.asgard_cherche_lecteur(text, boolean, boolean, boolean)
-- - Function: z_asgard.asgard_cherche_editeur(text, boolean, boolean, boolean)
-- - Function: z_asgard_admin.asgard_restaure_editeurs_lecteurs(text, boolean, boolean, boolean, boolean)
--
-- objets modifiés par le script :
-- - Table: z_asgard_admin.gestion_schema
-- - Function: z_asgard_admin.asgard_on_modify_gestion_schema_before()
--
-- objets supprimés par le script :
-- Néant.
--
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


-- MOT DE PASSE DE CONTRÔLE : 'x7-A;#rzo'


-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


------ 2.2 - TABLE GESTION_SCHEMA ------

-- Table: z_asgard_admin.gestion_schema

ALTER TABLE z_asgard_admin.gestion_schema
    ADD CONSTRAINT gestion_schema_no_system_schema CHECK (
        NOT nom_schema ~ ANY(
            ARRAY[
                '^pg_toast', '^pg_temp', '^pg_catalog$', '^public$', 
                '^information_schema$', '^topology$'
            ]
        )
    ) ;


------ 4.7 - NETTOYAGE DE LA TABLE DE GESTION ------

-- Function: z_asgard_admin.asgard_nettoyage_oids()

CREATE OR REPLACE FUNCTION z_asgard_admin.asgard_nettoyage_oids()
    RETURNS text
    LANGUAGE plpgsql
    AS $_$
/* Recalcule les OIDs des schémas et rôles référencés dans la table de gestion en fonction de leurs noms.

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

*/
DECLARE
    rec record ;
    e_mssg text ;
    e_detl text ;
    e_hint text ;
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
                            e_detl = PG_EXCEPTION_DETAIL ;
    RAISE EXCEPTION 'FNO0 > %', e_mssg
        USING DETAIL = e_detl,
            HINT = e_hint ;

END
$_$;

ALTER FUNCTION z_asgard_admin.asgard_nettoyage_oids()
    OWNER TO g_admin ;

COMMENT ON FUNCTION z_asgard_admin.asgard_nettoyage_oids() IS 'ASGARD. Recalcule les OIDs des schémas et rôles référencés dans la table de gestion en fonction de leurs noms.' ;


------ 4.19 - RECHERCHE DE LECTEURS ET EDITEURS ------

-- Function: z_asgard.asgard_cherche_lecteur(text, boolean, boolean, boolean)

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

COMMENT ON FUNCTION z_asgard.asgard_cherche_lecteur(text, boolean, boolean, boolean)  IS 'ASGARD. Au vu des privilèges établis, cherche le rôle le plus susceptible d''être qualifié de "lecteur" du schéma.' ;


-- Function: z_asgard.asgard_cherche_editeur(text, boolean, boolean, boolean)

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
/* Recalcule les éditeurs et lecteurs renseignés dans la table de gestion en fonction des droits effectifs.

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

*/
DECLARE
    rec record ;
    e_mssg text ;
    e_detl text ;
    e_hint text ;
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
                            e_detl = PG_EXCEPTION_DETAIL ;
    RAISE EXCEPTION 'FRE0 > %', e_mssg
        USING DETAIL = e_detl,
            HINT = e_hint ;

END
$_$;

ALTER FUNCTION z_asgard_admin.asgard_restaure_editeurs_lecteurs(text, boolean, boolean, boolean, boolean)
    OWNER TO g_admin ;

COMMENT ON FUNCTION z_asgard_admin.asgard_restaure_editeurs_lecteurs(text, boolean, boolean, boolean, boolean) IS 'ASGARD. Recalcule les éditeurs et lecteurs renseignés dans la table de gestion en fonction des droits effectifs.' ;


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

    ------- SCHEMA DEJA REFERENCE ------
    -- en cas d'INSERT portant sur un schéma actif déjà référencé
    -- dans la table de gestion, Asgard tente de déréférencer le
    -- schéma pour permettre au référencement de se dérouler sans
    -- erreur
    IF TG_OP = 'INSERT'
    THEN
        IF NEW.creation AND NEW.nom_schema IN (
                SELECT gestion_schema_usr.nom_schema
                    FROM z_asgard.gestion_schema_usr
                    WHERE creation
            )
        THEN
            RAISE NOTICE 'Le schéma % est déjà référencé dans la table de gestion. Tentative de dé-référencement préalable.', NEW.nom_schema ;
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

        -- pas de schéma système
        IF NEW.nom_schema ~ ANY(
            ARRAY[
                '^pg_toast', '^pg_temp', '^pg_catalog$', '^public$', 
                '^information_schema$', '^topology$'
            ]
        )
        THEN
            RAISE EXCEPTION 'TB27. Le référencement des schémas système n''est pas autorisé (schéma %).', NEW.nom_schema ;
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
