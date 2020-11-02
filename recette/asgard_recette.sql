-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
--
-- ASGARD - Système de gestion des droits pour PostgreSQL, version 1.2.1
-- > Script de recette.
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
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
--
-- schéma contenant les objets : z_asgard_recette
--
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


-----------------------------------------------------
------ 9 - RECETTE TECHNIQUE (TESTS UNITAIRES) ------
-----------------------------------------------------
/* 9.01 - Préparation et fonction chapeau
   9.02 - Bibliothèque de tests */
   
/* Les tests sont à exécuter :
- sur une base vierge où ont simplement été installées les
extensions postgres_fdw et asgard ;
- avec un super-utilisateur.

SELECT * FROM z_asgard_recette.execute_recette() ;

Tous les tests existent en deux versions, une forme avec noms d'objets
normalisés et une forme "b" avec noms d'objets ésotériques. */   
   
/*
-- FUNCTION: z_asgard_recette.t000()

CREATE OR REPLACE FUNCTION z_asgard_recette.t000()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
   e_mssg text ;
   e_detl text ;
BEGIN



    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                            e_detl = PG_EXCEPTION_DETAIL ;
    RAISE NOTICE '%', e_mssg
        USING DETAIL = e_detl ;
        
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t000() IS 'ASGARD recette. TEST : .' ;
*/
   
   
------ 9.01 - Préparation et fonction chapeau ------

-- SCHEMA: z_asgard_recette

CREATE SCHEMA IF NOT EXISTS z_asgard_recette ;

COMMENT ON SCHEMA z_asgard_recette IS 'ASGARD. Bibliothèque de fonctions pour la recette technique.' ;


-- FUNCTION: z_asgard_recette.execute_recette()

CREATE OR REPLACE FUNCTION z_asgard_recette.execute_recette()
    RETURNS TABLE (test text, description text)
    LANGUAGE plpgsql
    AS $_$
/* OBJET : Exécution de la recette : lance successivement toutes
           les fonctions de tests du schéma z_asgard_recette.
APPEL : SELECT * FROM z_asgard_recette.execute_recette() ;
ARGUMENTS : néant.
SORTIE : table des tests qui ont échoué. */
DECLARE
    l text[] ;
    test record ;
    succes boolean ;
BEGIN
    SET LOCAL client_min_messages = 'ERROR' ;
    -- empêche l'affichage des messages d'ASGARD
    
    FOR test IN (
            SELECT oid::regprocedure::text AS nom, proname::text AS ref
                FROM pg_catalog.pg_proc
                WHERE pronamespace = 'z_asgard_recette'::regnamespace::oid
                    AND proname ~ '^t[0-9]+b*$'
                ORDER BY proname
            ) 
    LOOP
        EXECUTE 'SELECT ' || test.nom
            INTO succes ;
        IF NOT succes OR succes IS NULL
        THEN
            l := array_append(l, test.ref) ;
        END IF ;
    END LOOP ;
    RETURN QUERY
        SELECT
            num,
            CASE WHEN num ~ 'b' THEN ' [noms non normalisés] ' ELSE '' END ||
            substring(
                obj_description(('z_asgard_recette.' || num || '()')::regprocedure, 'pg_proc'),
                '^ASGARD.recette[.].TEST.[:].(.*)[.]$'
                )
            FROM unnest(l) AS t (num)
            ORDER BY num ;
END
$_$ ;

COMMENT ON FUNCTION z_asgard_recette.execute_recette() IS 'ASGARD recette. Exécution de la recette.' ;



------ 9.02 - Bibliothèque de tests ------

-- FUNCTION: z_asgard_recette.t001()

CREATE OR REPLACE FUNCTION z_asgard_recette.t001()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
BEGIN

    ------ création ------
    CREATE SCHEMA c_bibliotheque ;
    
    SELECT creation
        INTO STRICT b
        FROM z_asgard.gestion_schema_usr
        WHERE nom_schema = 'c_bibliotheque' ;
        
    r := b ;
    
    SELECT count(*) = 1
        INTO STRICT b
        FROM pg_catalog.pg_namespace
        WHERE nspname = 'c_bibliotheque' ;
        
    r := r AND b ;
        
    ------ suppression ------
    DROP SCHEMA c_bibliotheque ;
    
    SELECT NOT creation
        INTO STRICT b
        FROM z_asgard.gestion_schema_usr
        WHERE nom_schema = 'c_bibliotheque' ;
        
    r := r AND b ;
    
    SELECT count(*) = 0
        INTO STRICT b
        FROM pg_catalog.pg_namespace
        WHERE nspname = 'c_bibliotheque' ;
        
    r := r AND b ;
    
    ------ effacement ------
    DELETE FROM z_asgard.gestion_schema_usr WHERE nom_schema = 'c_bibliotheque' ;
    
    SELECT count(*) = 0
        INTO STRICT b
        FROM z_asgard.gestion_schema_usr
        WHERE nom_schema = 'c_bibliotheque' ;
        
    r := r AND b ;
    
    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t001() IS 'ASGARD recette. TEST : création, suppression, effacement d''un schéma par commandes directes.' ;


-- FUNCTION: z_asgard_recette.t001b()

CREATE OR REPLACE FUNCTION z_asgard_recette.t001b()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
BEGIN

    ------ création ------
    CREATE SCHEMA "c_Bibliothèque" ;
    
    SELECT creation
        INTO STRICT b
        FROM z_asgard.gestion_schema_usr
        WHERE nom_schema = 'c_Bibliothèque' ;
        
    r := b ;
    
    SELECT count(*) = 1
        INTO STRICT b
        FROM pg_catalog.pg_namespace
        WHERE nspname = 'c_Bibliothèque' ;
        
    r := r AND b ;
        
    ------ suppression ------
    DROP SCHEMA "c_Bibliothèque" ;
    
    SELECT NOT creation
        INTO STRICT b
        FROM z_asgard.gestion_schema_usr
        WHERE nom_schema = 'c_Bibliothèque' ;
        
    r := r AND b ;
    
    SELECT count(*) = 0
        INTO STRICT b
        FROM pg_catalog.pg_namespace
        WHERE nspname = 'c_Bibliothèque' ;
        
    r := r AND b ;
    
    ------ effacement ------
    DELETE FROM z_asgard.gestion_schema_usr WHERE nom_schema = 'c_Bibliothèque' ;
    
    SELECT count(*) = 0
        INTO STRICT b
        FROM z_asgard.gestion_schema_usr
        WHERE nom_schema = 'c_Bibliothèque' ;
        
    r := r AND b ;
    
    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t001b() IS 'ASGARD recette. TEST : création, suppression, effacement d''un schéma par commandes directes.' ;



-- FUNCTION: z_asgard_recette.t002()

CREATE OR REPLACE FUNCTION z_asgard_recette.t002()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
BEGIN

    CREATE SCHEMA c_bibliotheque ;
    
    ------ modification du nom ------
    ALTER SCHEMA c_bibliotheque RENAME TO c_librairie ;
    
    SELECT count(*) = 1
        INTO STRICT b
        FROM z_asgard.gestion_schema_usr
        WHERE nom_schema = 'c_librairie' ;
        
    r := b ;
 
    SELECT count(*) = 0
        INTO STRICT b
        FROM z_asgard.gestion_schema_usr
        WHERE nom_schema = 'c_bibliotheque' ;
        
    r := r AND b ;
    
    SELECT count(*) = 1
        INTO STRICT b
        FROM pg_catalog.pg_namespace
        WHERE nspname = 'c_librairie' ;
        
    r := r AND b ;
 
    SELECT count(*) = 0
        INTO STRICT b
        FROM pg_catalog.pg_namespace
        WHERE nspname = 'c_bibliotheque' ;
        
    r := r AND b ;

    DROP SCHEMA c_librairie ;
    DELETE FROM z_asgard.gestion_schema_usr WHERE nom_schema = 'c_librairie' ;
    
    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t002() IS 'ASGARD recette. TEST : changement de nom d''un schéma par commande directe.' ;


-- FUNCTION: z_asgard_recette.t002b()

CREATE OR REPLACE FUNCTION z_asgard_recette.t002b()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
BEGIN

    CREATE SCHEMA "C_Bibliothèque" ;
    
    ------ modification du nom ------
    ALTER SCHEMA "C_Bibliothèque" RENAME TO "C_Librairie" ;
    
    SELECT count(*) = 1
        INTO STRICT b
        FROM z_asgard.gestion_schema_usr
        WHERE nom_schema = 'C_Librairie' ;
        
    r := b ;
 
    SELECT count(*) = 0
        INTO STRICT b
        FROM z_asgard.gestion_schema_usr
        WHERE nom_schema = 'C_Bibliothèque' ;
        
    r := r AND b ;
    
    SELECT count(*) = 1
        INTO STRICT b
        FROM pg_catalog.pg_namespace
        WHERE nspname = 'C_Librairie' ;
        
    r := r AND b ;
 
    SELECT count(*) = 0
        INTO STRICT b
        FROM pg_catalog.pg_namespace
        WHERE nspname = 'C_Bibliothèque' ;
        
    r := r AND b ;

    DROP SCHEMA "C_Librairie" ;
    DELETE FROM z_asgard.gestion_schema_usr WHERE nom_schema = 'C_Librairie' ;
    
    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t002b() IS 'ASGARD recette. TEST : changement de nom d''un schéma par commande directe.' ;


-- FUNCTION: z_asgard_recette.t003()

CREATE OR REPLACE FUNCTION z_asgard_recette.t003()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
BEGIN

    CREATE SCHEMA c_bibliotheque ;
  
    ------ modification du propriétaire ------
    ALTER SCHEMA c_bibliotheque OWNER TO g_admin_ext ;
    
    SELECT producteur = 'g_admin_ext'
        INTO STRICT b
        FROM z_asgard.gestion_schema_usr
        WHERE nom_schema = 'c_bibliotheque' ;
        
    r := b ;
    
    SELECT nspowner::regrole::text = 'g_admin_ext'
        INTO STRICT b
        FROM pg_catalog.pg_namespace
        WHERE nspname = 'c_bibliotheque' ;
        
    r := r AND b ; 


    DROP SCHEMA c_bibliotheque ;
    DELETE FROM z_asgard.gestion_schema_usr WHERE nom_schema = 'c_bibliotheque' ;
        
    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t003() IS 'ASGARD recette. TEST : changement de propriétaire d''un schéma par commande directe.' ;

-- FUNCTION: z_asgard_recette.t003b()

CREATE OR REPLACE FUNCTION z_asgard_recette.t003b()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
BEGIN

    CREATE ROLE "Admin EXT" ;

    CREATE SCHEMA "c_Bibliothèque" ;
  
    ------ modification du propriétaire ------
    ALTER SCHEMA "c_Bibliothèque" OWNER TO "Admin EXT" ;
    
    SELECT producteur = 'Admin EXT'
        INTO STRICT b
        FROM z_asgard.gestion_schema_usr
        WHERE nom_schema = 'c_Bibliothèque' ;
        
    r := b ;
    
    SELECT nspowner::regrole::text = '"Admin EXT"'
        INTO STRICT b
        FROM pg_catalog.pg_namespace
        WHERE nspname = 'c_Bibliothèque' ;
        
    r := r AND b ; 


    DROP SCHEMA "c_Bibliothèque" ;
    DELETE FROM z_asgard.gestion_schema_usr WHERE nom_schema = 'c_Bibliothèque' ;
    
    DROP ROLE "Admin EXT" ;
        
    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t003b() IS 'ASGARD recette. TEST : changement de propriétaire d''un schéma par commande directe.' ;


-- FUNCTION: z_asgard_recette.t004()

CREATE OR REPLACE FUNCTION z_asgard_recette.t004()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
BEGIN

    ------ création par la table de gestion ------
    INSERT INTO z_asgard.gestion_schema_usr (nom_schema, producteur, creation)
        VALUES ('c_bibliotheque', 'g_admin_ext', True) ;
    
    SELECT nspowner::regrole::text = 'g_admin_ext'
        INTO STRICT b
        FROM pg_catalog.pg_namespace
        WHERE nspname = 'c_bibliotheque' ;
        
    r := b ; 

    DROP SCHEMA c_bibliotheque ;
    DELETE FROM z_asgard.gestion_schema_usr WHERE nom_schema = 'c_bibliotheque' ;
        
    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t004() IS 'ASGARD recette. TEST : création d''un schéma par la table de gestion (une étape).' ;


-- FUNCTION: z_asgard_recette.t004b()

CREATE OR REPLACE FUNCTION z_asgard_recette.t004b()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
BEGIN

    CREATE ROLE "Admin EXT" ;

    ------ création par la table de gestion ------
    INSERT INTO z_asgard.gestion_schema_usr (nom_schema, producteur, creation)
        VALUES ('c_Bibliothèque', 'Admin EXT', True) ;
    
    SELECT nspowner::regrole::text = '"Admin EXT"'
        INTO STRICT b
        FROM pg_catalog.pg_namespace
        WHERE nspname = 'c_Bibliothèque' ;
        
    r := b ; 

    DROP SCHEMA "c_Bibliothèque" ;
    DELETE FROM z_asgard.gestion_schema_usr WHERE nom_schema = 'c_Bibliothèque' ;
    
    DROP ROLE "Admin EXT" ;
        
    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t004b() IS 'ASGARD recette. TEST : création d''un schéma par la table de gestion (une étape).' ;


-- FUNCTION: z_asgard_recette.t005()

CREATE OR REPLACE FUNCTION z_asgard_recette.t005()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
BEGIN

    ------ préparation dans la table de gestion ------
    INSERT INTO z_asgard.gestion_schema_usr (nom_schema, producteur)
        VALUES ('c_bibliotheque', 'g_admin_ext') ;
    
    SELECT count(*) = 0
        INTO STRICT b
        FROM pg_catalog.pg_namespace
        WHERE nspname = 'c_bibliotheque' ;
        
    r := b ; 
    
    ------ création par la table de gestion ------
    UPDATE z_asgard.gestion_schema_usr
        SET creation = True
        WHERE nom_schema = 'c_bibliotheque' ;
    
    SELECT nspowner::regrole::text = 'g_admin_ext'
        INTO STRICT b
        FROM pg_catalog.pg_namespace
        WHERE nspname = 'c_bibliotheque' ;

    r := r AND b ;

    DROP SCHEMA c_bibliotheque ;
    DELETE FROM z_asgard.gestion_schema_usr WHERE nom_schema = 'c_bibliotheque' ;
        
    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t005() IS 'ASGARD recette. TEST : création d''un schéma par la table de gestion (deux étapes).' ;


-- FUNCTION: z_asgard_recette.t005b()

CREATE OR REPLACE FUNCTION z_asgard_recette.t005b()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
BEGIN

    CREATE ROLE "Admin EXT" ;

    ------ préparation dans la table de gestion ------
    INSERT INTO z_asgard.gestion_schema_usr (nom_schema, producteur)
        VALUES ('c_Bibliothèque', 'Admin EXT') ;
    
    SELECT count(*) = 0
        INTO STRICT b
        FROM pg_catalog.pg_namespace
        WHERE nspname = 'c_Bibliothèque' ;
        
    r := b ; 
    
    ------ création par la table de gestion ------
    UPDATE z_asgard.gestion_schema_usr
        SET creation = True
        WHERE nom_schema = 'c_Bibliothèque' ;
    
    SELECT nspowner::regrole::text = '"Admin EXT"'
        INTO STRICT b
        FROM pg_catalog.pg_namespace
        WHERE nspname = 'c_Bibliothèque' ;

    r := r AND b ;

    DROP SCHEMA "c_Bibliothèque" ;
    DELETE FROM z_asgard.gestion_schema_usr WHERE nom_schema = 'c_Bibliothèque' ;
    
    DROP ROLE "Admin EXT" ;
    
    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t005b() IS 'ASGARD recette. TEST : création d''un schéma par la table de gestion (deux étapes).' ;


-- FUNCTION: z_asgard_recette.t006()

CREATE OR REPLACE FUNCTION z_asgard_recette.t006()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
BEGIN

    CREATE SCHEMA c_bibliotheque ; 
    
    ------ modification du producteur ------
    UPDATE z_asgard.gestion_schema_usr
        SET producteur = 'g_admin_ext'
        WHERE nom_schema = 'c_bibliotheque' ;
    
    SELECT nspowner::regrole::text = 'g_admin_ext'
        INTO STRICT b
        FROM pg_catalog.pg_namespace
        WHERE nspname = 'c_bibliotheque' ;

    r := b ;

    DROP SCHEMA c_bibliotheque ;
    DELETE FROM z_asgard.gestion_schema_usr WHERE nom_schema = 'c_bibliotheque' ;
        
    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t006() IS 'ASGARD recette. TEST : modification du producteur par la table de gestion.' ;

-- FUNCTION: z_asgard_recette.t006b()

CREATE OR REPLACE FUNCTION z_asgard_recette.t006b()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
BEGIN

    CREATE ROLE "Admin EXT" ;

    CREATE SCHEMA "c_Bibliothèque" ; 
    
    ------ modification du producteur ------
    UPDATE z_asgard.gestion_schema_usr
        SET producteur = 'Admin EXT'
        WHERE nom_schema = 'c_Bibliothèque' ;
    
    SELECT nspowner::regrole::text = '"Admin EXT"'
        INTO STRICT b
        FROM pg_catalog.pg_namespace
        WHERE nspname = 'c_Bibliothèque' ;

    r := b ;

    DROP SCHEMA "c_Bibliothèque" ;
    DELETE FROM z_asgard.gestion_schema_usr WHERE nom_schema = 'c_Bibliothèque' ;
    
    DROP ROLE "Admin EXT" ;
        
    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t006b() IS 'ASGARD recette. TEST : modification du producteur par la table de gestion.' ;


-- FUNCTION: z_asgard_recette.t007()

CREATE OR REPLACE FUNCTION z_asgard_recette.t007()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
   e_mssg text ;
   e_detl text ;
BEGIN

    CREATE SCHEMA c_bibliotheque ; 
    
    ------ dé-création (erreur) ------
    UPDATE z_asgard.gestion_schema_usr
        SET creation = False
        WHERE nom_schema = 'c_bibliotheque' ;

    DROP SCHEMA c_bibliotheque ;
    DELETE FROM z_asgard.gestion_schema_usr WHERE nom_schema = 'c_bibliotheque' ;
        
    RETURN False ;
    
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                            e_detl = PG_EXCEPTION_DETAIL ;
                            
    RETURN e_mssg ~ 'TB4[.]' OR e_detl ~ 'TB4[.]' OR False ;

END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t007() IS 'ASGARD recette. TEST : interdiction passage true/false de creation.' ;

-- FUNCTION: z_asgard_recette.t007b()

CREATE OR REPLACE FUNCTION z_asgard_recette.t007b()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
   e_mssg text ;
   e_detl text ;
BEGIN

    CREATE SCHEMA "c_Bibliothèque" ; 
    
    ------ dé-création (erreur) ------
    UPDATE z_asgard.gestion_schema_usr
        SET creation = False
        WHERE nom_schema = 'c_Bibliothèque' ;

    DROP SCHEMA "c_Bibliothèque" ;
    DELETE FROM z_asgard.gestion_schema_usr WHERE nom_schema = 'c_Bibliothèque' ;
        
    RETURN False ;
    
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                            e_detl = PG_EXCEPTION_DETAIL ;
                            
    RETURN e_mssg ~ 'TB4[.]' OR e_detl ~ 'TB4[.]' OR False ;

END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t007b() IS 'ASGARD recette. TEST : interdiction passage true/false de creation.' ;


-- FUNCTION: z_asgard_recette.t008()

CREATE OR REPLACE FUNCTION z_asgard_recette.t008()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
   e_mssg text ;
   e_detl text ;
BEGIN

    CREATE SCHEMA c_bibliotheque ; 
    
    ------ effacement schéma existant (erreur) ------
    DELETE FROM z_asgard.gestion_schema_usr
        WHERE nom_schema = 'c_bibliotheque' ;

    DROP SCHEMA c_bibliotheque ;
    DELETE FROM z_asgard.gestion_schema_usr WHERE nom_schema = 'c_bibliotheque' ;
        
    RETURN False ;
    
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                            e_detl = PG_EXCEPTION_DETAIL ;
                            
    RETURN e_mssg ~ 'TB2[.]' OR e_detl ~ 'TB2[.]' OR False ;

END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t008() IS 'ASGARD recette. TEST : interdiction de l''effacement si creation vaut True.' ;

-- FUNCTION: z_asgard_recette.t008b()

CREATE OR REPLACE FUNCTION z_asgard_recette.t008b()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
   e_mssg text ;
   e_detl text ;
BEGIN

    CREATE SCHEMA "c_Bibliothèque" ; 
    
    ------ effacement schéma existant (erreur) ------
    DELETE FROM z_asgard.gestion_schema_usr
        WHERE nom_schema = 'c_Bibliothèque' ;

    DROP SCHEMA "c_Bibliothèque" ;
    DELETE FROM z_asgard.gestion_schema_usr WHERE nom_schema = 'c_Bibliothèque' ;
        
    RETURN False ;
    
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                            e_detl = PG_EXCEPTION_DETAIL ;
                            
    RETURN e_mssg ~ 'TB2[.]' OR e_detl ~ 'TB2[.]' OR False ;

END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t008b() IS 'ASGARD recette. TEST : interdiction de l''effacement si creation vaut True.' ;


-- FUNCTION: z_asgard_recette.t009()

CREATE OR REPLACE FUNCTION z_asgard_recette.t009()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
BEGIN

    CREATE SCHEMA c_bibliotheque AUTHORIZATION g_admin_ext ;
    
    ------ création d''une table ------
    CREATE TABLE c_bibliotheque.journal_du_mur (id serial PRIMARY KEY, jour date, entree text) ;
    
    SELECT relowner::regrole::text = 'g_admin_ext'
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'journal_du_mur' ;

    r := b ;
    
    SELECT relowner::regrole::text = 'g_admin_ext'
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'journal_du_mur_id_seq' ;
        
    r := r AND b ;

    DROP SCHEMA c_bibliotheque CASCADE ;
    DELETE FROM z_asgard.gestion_schema_usr WHERE nom_schema = 'c_bibliotheque' ;
        
    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t009() IS 'ASGARD recette. TEST : création d''une table et d''une séquence.' ;

-- FUNCTION: z_asgard_recette.t009b()

CREATE OR REPLACE FUNCTION z_asgard_recette.t009b()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
BEGIN

    CREATE ROLE "Admin EXT" ;

    CREATE SCHEMA "c_Bibliothèque" AUTHORIZATION "Admin EXT" ;
    
    ------ création d''une table ------
    CREATE TABLE "c_Bibliothèque"."Journal du mur" (id serial PRIMARY KEY, jour date, entree text) ;
    
    SELECT relowner::regrole::text = '"Admin EXT"'
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'Journal du mur' ;

    r := b ;
    
    SELECT relowner::regrole::text = '"Admin EXT"'
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'Journal du mur_id_seq' ;
        
    r := r AND b ;

    DROP SCHEMA "c_Bibliothèque" CASCADE ;
    DELETE FROM z_asgard.gestion_schema_usr WHERE nom_schema = 'c_Bibliothèque' ;
    
    DROP ROLE "Admin EXT" ;
    
    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t009b() IS 'ASGARD recette. TEST : création d''une table et d''une séquence.' ;


-- FUNCTION: z_asgard_recette.t010()

CREATE OR REPLACE FUNCTION z_asgard_recette.t010()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
BEGIN

    CREATE SCHEMA c_bibliotheque AUTHORIZATION g_admin_ext ;
    CREATE TABLE c_bibliotheque.journal_du_mur (id serial PRIMARY KEY, jour date, entree text) ;
    
    ------ modification du propriétaire de la table ------
    ALTER TABLE c_bibliotheque.journal_du_mur OWNER TO g_admin ;
    
    SELECT relowner::regrole::text = 'g_admin_ext'
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'journal_du_mur' ;

    r := b ;
    
    SELECT relowner::regrole::text = 'g_admin_ext'
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'journal_du_mur_id_seq' ;
        
    r := r AND b ;

    DROP SCHEMA c_bibliotheque CASCADE ;
    DELETE FROM z_asgard.gestion_schema_usr WHERE nom_schema = 'c_bibliotheque' ;
        
    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t010() IS 'ASGARD recette. TEST : annulation de la modification du propriétaire d''une table (avec séquence associée).' ;

-- FUNCTION: z_asgard_recette.t010b()

CREATE OR REPLACE FUNCTION z_asgard_recette.t010b()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
BEGIN

    CREATE ROLE "Admin EXT" ;
    CREATE ROLE "Admin" ;

    CREATE SCHEMA "c_Bibliothèque" AUTHORIZATION "Admin EXT" ;
    CREATE TABLE "c_Bibliothèque"."Journal du mur" (id serial PRIMARY KEY, jour date, entree text) ;
    
    ------ modification du propriétaire de la table ------
    ALTER TABLE "c_Bibliothèque"."Journal du mur" OWNER TO "Admin" ;
    
    SELECT relowner::regrole::text = '"Admin EXT"'
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'Journal du mur' ;

    r := b ;
    
    SELECT relowner::regrole::text = '"Admin EXT"'
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'Journal du mur_id_seq' ;
        
    r := r AND b ;

    DROP SCHEMA "c_Bibliothèque" CASCADE ;
    DELETE FROM z_asgard.gestion_schema_usr WHERE nom_schema = 'c_Bibliothèque' ;
    
    DROP ROLE "Admin EXT" ;
    DROP ROLE "Admin" ;
    
    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t010b() IS 'ASGARD recette. TEST : annulation de la modification du propriétaire d''une table (avec séquence associée).' ;


-- FUNCTION: z_asgard_recette.t011()

CREATE OR REPLACE FUNCTION z_asgard_recette.t011()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
BEGIN

    CREATE SCHEMA c_bibliotheque AUTHORIZATION g_admin_ext ;
    
    ------ révocation d''un privilège ------
   REVOKE CREATE ON SCHEMA c_bibliotheque FROM g_admin_ext ;
    
    SELECT nspacl::text ~ ('g_admin_ext=U' || '[/]' || nspowner::regrole::text)
        INTO STRICT b
        FROM pg_catalog.pg_namespace
        WHERE nspname = 'c_bibliotheque' ;

    r := b ;
    
    ALTER SCHEMA c_bibliotheque OWNER TO g_admin ;

    SELECT nspacl::text ~ ('g_admin=U' || '[/]' || nspowner::regrole::text)
        INTO STRICT b
        FROM pg_catalog.pg_namespace
        WHERE nspname = 'c_bibliotheque' ;
        
    r := r AND b ;

    DROP SCHEMA c_bibliotheque ;
    DELETE FROM z_asgard.gestion_schema_usr WHERE nom_schema = 'c_bibliotheque' ;
        
    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t011() IS 'ASGARD recette. TEST : transmission des modifications manuelles des droits du producteur (schéma).' ;

-- FUNCTION: z_asgard_recette.t011b()

CREATE OR REPLACE FUNCTION z_asgard_recette.t011b()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
BEGIN

    CREATE ROLE "Admin EXT" ;
    CREATE ROLE "Admin" ;

    CREATE SCHEMA "c_Bibliothèque" AUTHORIZATION "Admin EXT" ;
    
    ------ révocation d''un privilège ------
    REVOKE CREATE ON SCHEMA "c_Bibliothèque" FROM "Admin EXT" ;
    
    SELECT array_to_string(nspacl, ',') ~ ('"Admin EXT"=U' || '[/]' || z_asgard.asgard_role_trans_acl(nspowner::regrole))
        INTO STRICT b
        FROM pg_catalog.pg_namespace
        WHERE nspname = 'c_Bibliothèque' ;

    r := b ;
    
    ALTER SCHEMA "c_Bibliothèque" OWNER TO "Admin" ;

    SELECT array_to_string(nspacl, ',') ~ ('Admin=U/Admin')
        INTO STRICT b
        FROM pg_catalog.pg_namespace
        WHERE nspname = 'c_Bibliothèque' ;
        
    r := r AND b ;

    DROP SCHEMA "c_Bibliothèque" ;
    DELETE FROM z_asgard.gestion_schema_usr WHERE nom_schema = 'c_Bibliothèque' ;
    
    DROP ROLE "Admin EXT" ;
    DROP ROLE "Admin" ;
    
    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t011b() IS 'ASGARD recette. TEST : transmission des modifications manuelles des droits du producteur (schéma).' ;


-- FUNCTION: z_asgard_recette.t012()

CREATE OR REPLACE FUNCTION z_asgard_recette.t012()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
BEGIN

    CREATE SCHEMA c_bibliotheque AUTHORIZATION g_admin_ext ;
    CREATE TABLE c_bibliotheque.journal_du_mur (id serial PRIMARY KEY, jour date, entree text) ;
    
    ------ révocation d''un privilège ------
    REVOKE DELETE ON TABLE c_bibliotheque.journal_du_mur FROM g_admin_ext ;
    
    SELECT relacl::text ~ ('g_admin_ext=[rwaDxt]{6}' || '[/]' || relowner::regrole::text)
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'journal_du_mur' ;

    r := b ;
    
    ALTER SCHEMA c_bibliotheque OWNER TO g_admin ;

    SELECT relacl::text ~ ('g_admin=[rwaDxt]{6}' || '[/]' || relowner::regrole::text)
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'journal_du_mur' ;
        
    r := r AND b ;

    DROP SCHEMA c_bibliotheque CASCADE ;
    DELETE FROM z_asgard.gestion_schema_usr WHERE nom_schema = 'c_bibliotheque' ;
        
    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t012() IS 'ASGARD recette. TEST : transmission des modifications manuelles des droits du producteur (table).' ;

-- FUNCTION: z_asgard_recette.t012b()

CREATE OR REPLACE FUNCTION z_asgard_recette.t012b()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
BEGIN

    CREATE ROLE "Admin EXT" ;
    CREATE ROLE "Admin" ;

    CREATE SCHEMA "c_Bibliothèque" AUTHORIZATION "Admin EXT" ;
    CREATE TABLE "c_Bibliothèque"."Journal du mur" (id serial PRIMARY KEY, jour date, entree text) ;
    
    ------ révocation d''un privilège ------
    REVOKE DELETE ON TABLE "c_Bibliothèque"."Journal du mur" FROM "Admin EXT" ;
    
    SELECT array_to_string(relacl, ',') ~ ('"Admin EXT"=[rwaDxt]{6}[/]"Admin EXT"')
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'Journal du mur' ;

    r := b ;
    
    ALTER SCHEMA "c_Bibliothèque" OWNER TO "Admin" ;

    SELECT array_to_string(relacl, ',') ~ ('Admin=[rwaDxt]{6}[/]Admin')
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'Journal du mur' ;
        
    r := r AND b ;

    DROP SCHEMA "c_Bibliothèque" CASCADE ;
    DELETE FROM z_asgard.gestion_schema_usr WHERE nom_schema = 'c_Bibliothèque' ;
    
    DROP ROLE "Admin EXT" ;
    DROP ROLE "Admin" ;
    
    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t012b() IS 'ASGARD recette. TEST : transmission des modifications manuelles des droits du producteur (table).' ;


-- FUNCTION: z_asgard_recette.t013()

CREATE OR REPLACE FUNCTION z_asgard_recette.t013()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
BEGIN
    
    CREATE ROLE g_admin_rec1 ;
    CREATE ROLE g_admin_rec2 ;
    
    ------ permission de g_admin sur le producteur (création) ------
    CREATE SCHEMA c_bibliotheque AUTHORIZATION g_admin_rec1 ;
    
    SELECT pg_has_role('g_admin', 'g_admin_rec1', 'USAGE')
        INTO STRICT b ;

    r := b ;
    
    ------ permission de g_admin sur le producteur (modification) ------
    ALTER SCHEMA c_bibliotheque OWNER TO g_admin_rec2 ;
    
    SELECT pg_has_role('g_admin', 'g_admin_rec2', 'USAGE')
        INTO STRICT b ;

    r := b ;

    DROP SCHEMA c_bibliotheque ;
    DELETE FROM z_asgard.gestion_schema_usr WHERE nom_schema = 'c_bibliotheque' ;
    DROP ROLE g_admin_rec1 ;
    DROP ROLE g_admin_rec2 ;
        
    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t013() IS 'ASGARD recette. TEST : permission de g_admin sur le producteur.' ;

-- FUNCTION: z_asgard_recette.t013b()

CREATE OR REPLACE FUNCTION z_asgard_recette.t013b()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
BEGIN
    
    CREATE ROLE "Admin rec1" ;
    CREATE ROLE "Admin rec2";
    
    ------ permission de g_admin sur le producteur (création) ------
    CREATE SCHEMA "c_Bibliothèque" AUTHORIZATION "Admin rec1" ;
    
    SELECT pg_has_role('g_admin', 'Admin rec1', 'USAGE')
        INTO STRICT b ;

    r := b ;
    
    ------ permission de "Admin" sur le producteur (modification) ------
    ALTER SCHEMA "c_Bibliothèque" OWNER TO "Admin rec2" ;
    
    SELECT pg_has_role('g_admin', 'Admin rec1', 'USAGE')
        INTO STRICT b ;

    r := b ;

    DROP SCHEMA "c_Bibliothèque" ;
    DELETE FROM z_asgard.gestion_schema_usr WHERE nom_schema = 'c_Bibliothèque' ;
    DROP ROLE "Admin rec1" ;
    DROP ROLE "Admin rec2" ;
        
    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t013b() IS 'ASGARD recette. TEST : permission de g_admin sur le producteur.' ;


-- FUNCTION: z_asgard_recette.t014()

CREATE OR REPLACE FUNCTION z_asgard_recette.t014()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
BEGIN

    CREATE SCHEMA c_bibliotheque ; 
    
    ------ modification du nom du schéma ------
    UPDATE z_asgard.gestion_schema_usr
        SET nom_schema = 'c_librairie'
        WHERE nom_schema = 'c_bibliotheque' ;
    
    SELECT count(*) = 0
        INTO STRICT b
        FROM pg_catalog.pg_namespace
        WHERE nspname = 'c_bibliotheque' ;

    r := b ;
    
    SELECT count(*) = 1
        INTO STRICT b
        FROM pg_catalog.pg_namespace
        WHERE nspname = 'c_librairie' ;

    r := r AND b ;

    DROP SCHEMA c_librairie ;
    DELETE FROM z_asgard.gestion_schema_usr WHERE nom_schema = 'c_librairie' ;
        
    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t014() IS 'ASGARD recette. TEST : modification du nom du schéma par la table de gestion.' ;

-- FUNCTION: z_asgard_recette.t014b()

CREATE OR REPLACE FUNCTION z_asgard_recette.t014b()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
BEGIN

    CREATE SCHEMA "c_Bibliothèque" ; 
    
    ------ modification du nom du schéma ------
    UPDATE z_asgard.gestion_schema_usr
        SET nom_schema = 'c_Librairie'
        WHERE nom_schema = 'c_Bibliothèque' ;
    
    SELECT count(*) = 0
        INTO STRICT b
        FROM pg_catalog.pg_namespace
        WHERE nspname = 'c_Bibliothèque' ;

    r := b ;
    
    SELECT count(*) = 1
        INTO STRICT b
        FROM pg_catalog.pg_namespace
        WHERE nspname = 'c_Librairie' ;

    r := r AND b ;

    DROP SCHEMA "c_Librairie" ;
    DELETE FROM z_asgard.gestion_schema_usr WHERE nom_schema = 'c_Librairie' ;
        
    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t014b() IS 'ASGARD recette. TEST : modification du nom du schéma par la table de gestion.' ;


-- FUNCTION: z_asgard_recette.t015()

CREATE OR REPLACE FUNCTION z_asgard_recette.t015()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
BEGIN

    CREATE SCHEMA c_bibliotheque ;
    CREATE TABLE c_bibliotheque.journal_du_mur (id serial PRIMARY KEY, jour date, entree text) ;
    
    ------ désignation de l''éditeur ------
    UPDATE z_asgard.gestion_schema_usr
        SET editeur = 'g_admin_ext'
        WHERE nom_schema = 'c_bibliotheque' ;
        
    CREATE TABLE c_bibliotheque.journal_du_mur_bis (id serial PRIMARY KEY, jour date, entree text) ;
    
    SELECT nspacl::text ~ ('g_admin_ext=U' || '[/]' || nspowner::regrole::text)
        INTO STRICT b
        FROM pg_catalog.pg_namespace
        WHERE nspname = 'c_bibliotheque' ;
        
    r := b ;
    
    SELECT relacl::text ~ ('g_admin_ext=[rwad]{4}' || '[/]' || relowner::regrole::text)
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'journal_du_mur' ;
        
    r := r AND b ;
    
    SELECT relacl::text ~ ('g_admin_ext=[rU]{2}' || '[/]' || relowner::regrole::text)
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'journal_du_mur_id_seq' ;
        
    r := r AND b ;
    
    SELECT relacl::text ~ ('g_admin_ext=[rwad]{4}' || '[/]' || relowner::regrole::text)
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'journal_du_mur_bis' ;
        
    r := r AND b ;
    
    SELECT relacl::text ~ ('g_admin_ext=[rU]{2}' || '[/]' || relowner::regrole::text)
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'journal_du_mur_bis_id_seq' ;
        
    r := r AND b ;

    DROP SCHEMA c_bibliotheque CASCADE ;
    DELETE FROM z_asgard.gestion_schema_usr WHERE nom_schema = 'c_bibliotheque' ;
        
    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t015() IS 'ASGARD recette. TEST : désignation d''un éditeur.' ;

-- FUNCTION: z_asgard_recette.t015b()

CREATE OR REPLACE FUNCTION z_asgard_recette.t015b()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
BEGIN

    CREATE ROLE "Admin EXT" ;

    CREATE SCHEMA "c_Bibliothèque" ;
    CREATE TABLE "c_Bibliothèque"."Journal du mur" (id serial PRIMARY KEY, jour date, entree text) ;
    
    ------ désignation de l''éditeur ------
    UPDATE z_asgard.gestion_schema_usr
        SET editeur = 'Admin EXT'
        WHERE nom_schema = 'c_Bibliothèque' ;
        
    CREATE TABLE "c_Bibliothèque"."Journal du mur_bis" (id serial PRIMARY KEY, jour date, entree text) ;
    
    SELECT array_to_string(nspacl, ',') ~ ('"Admin EXT"=U' || '[/]' || z_asgard.asgard_role_trans_acl(nspowner::regrole))
        INTO STRICT b
        FROM pg_catalog.pg_namespace
        WHERE nspname = 'c_Bibliothèque' ;
        
    r := b ;
    
    SELECT array_to_string(relacl, ',') ~ ('"Admin EXT"=[rwad]{4}' || '[/]' || z_asgard.asgard_role_trans_acl(relowner::regrole))
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'Journal du mur' ;
        
    r := r AND b ;
    
    SELECT array_to_string(relacl, ',') ~ ('"Admin EXT"=[rU]{2}' || '[/]' || z_asgard.asgard_role_trans_acl(relowner::regrole))
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'Journal du mur_id_seq' ;
        
    r := r AND b ;
    
    SELECT array_to_string(relacl, ',') ~ ('"Admin EXT"=[rwad]{4}' || '[/]' || z_asgard.asgard_role_trans_acl(relowner::regrole))
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'Journal du mur_bis' ;
        
    r := r AND b ;
    
    SELECT array_to_string(relacl, ',') ~ ('"Admin EXT"=[rU]{2}' || '[/]' || z_asgard.asgard_role_trans_acl(relowner::regrole))
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'Journal du mur_bis_id_seq' ;
        
    r := r AND b ;

    DROP SCHEMA "c_Bibliothèque" CASCADE ;
    DELETE FROM z_asgard.gestion_schema_usr WHERE nom_schema = 'c_Bibliothèque' ;
    
    DROP ROLE "Admin EXT" ;
    
    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t015b() IS 'ASGARD recette. TEST : désignation d''un éditeur.' ;


-- FUNCTION: z_asgard_recette.t016()

CREATE OR REPLACE FUNCTION z_asgard_recette.t016()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
BEGIN

    CREATE SCHEMA c_bibliotheque ;
    CREATE TABLE c_bibliotheque.journal_du_mur (id serial PRIMARY KEY, jour date, entree text) ;
    
    ------ désignation du lecteur ------
    UPDATE z_asgard.gestion_schema_usr
        SET lecteur = 'g_admin_ext'
        WHERE nom_schema = 'c_bibliotheque' ;
        
    CREATE TABLE c_bibliotheque.journal_du_mur_bis (id serial PRIMARY KEY, jour date, entree text) ;
    
    SELECT nspacl::text ~ ('g_admin_ext=U' || '[/]' || nspowner::regrole::text)
        INTO STRICT b
        FROM pg_catalog.pg_namespace
        WHERE nspname = 'c_bibliotheque' ;
        
    r := b ;
    
    SELECT relacl::text ~ ('g_admin_ext=r' || '[/]' || relowner::regrole::text)
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'journal_du_mur' ;
        
    r := r AND b ;
    
    SELECT relacl::text ~ ('g_admin_ext=r' || '[/]' || relowner::regrole::text)
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'journal_du_mur_id_seq' ;
        
    r := r AND b ;
    
    SELECT relacl::text ~ ('g_admin_ext=r' || '[/]' || relowner::regrole::text)
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'journal_du_mur_bis' ;
        
    r := r AND b ;
    
    SELECT relacl::text ~ ('g_admin_ext=r' || '[/]' || relowner::regrole::text)
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'journal_du_mur_bis_id_seq' ;
        
    r := r AND b ;

    DROP SCHEMA c_bibliotheque CASCADE ;
    DELETE FROM z_asgard.gestion_schema_usr WHERE nom_schema = 'c_bibliotheque' ;
        
    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t016() IS 'ASGARD recette. TEST : désignation d''un lecteur.' ;

-- FUNCTION: z_asgard_recette.t016b()

CREATE OR REPLACE FUNCTION z_asgard_recette.t016b()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
BEGIN

    CREATE ROLE "Admin EXT" ;

    CREATE SCHEMA "c_Bibliothèque" ;
    CREATE TABLE "c_Bibliothèque"."Journal du mur" (id serial PRIMARY KEY, jour date, entree text) ;
    
    ------ désignation du lecteur ------
    UPDATE z_asgard.gestion_schema_usr
        SET lecteur = 'Admin EXT'
        WHERE nom_schema = 'c_Bibliothèque' ;
        
    CREATE TABLE "c_Bibliothèque"."Journal du mur_bis" (id serial PRIMARY KEY, jour date, entree text) ;
    
    SELECT array_to_string(nspacl, ',') ~ ('"Admin EXT"=U' || '[/]' || z_asgard.asgard_role_trans_acl(nspowner::regrole))
        INTO STRICT b
        FROM pg_catalog.pg_namespace
        WHERE nspname = 'c_Bibliothèque' ;
        
    r := b ;
    
    SELECT array_to_string(relacl, ',') ~ ('"Admin EXT"=r' || '[/]' || z_asgard.asgard_role_trans_acl(relowner::regrole))
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'Journal du mur' ;
        
    r := r AND b ;
    
    SELECT array_to_string(relacl, ',') ~ ('"Admin EXT"=r' || '[/]' || z_asgard.asgard_role_trans_acl(relowner::regrole))
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'Journal du mur_id_seq' ;
        
    r := r AND b ;
    
    SELECT array_to_string(relacl, ',') ~ ('"Admin EXT"=r' || '[/]' || z_asgard.asgard_role_trans_acl(relowner::regrole))
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'Journal du mur_bis' ;
        
    r := r AND b ;
    
    SELECT array_to_string(relacl, ',') ~ ('"Admin EXT"=r' || '[/]' || z_asgard.asgard_role_trans_acl(relowner::regrole))
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'Journal du mur_bis_id_seq' ;
        
    r := r AND b ;

    DROP SCHEMA "c_Bibliothèque" CASCADE ;
    DELETE FROM z_asgard.gestion_schema_usr WHERE nom_schema = 'c_Bibliothèque' ;
    
    DROP ROLE "Admin EXT" ;
    
    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t016b() IS 'ASGARD recette. TEST : désignation d''un lecteur.' ;



-- FUNCTION: z_asgard_recette.t017()

CREATE OR REPLACE FUNCTION z_asgard_recette.t017()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
BEGIN

    CREATE SCHEMA c_bibliotheque ;
    CREATE TABLE c_bibliotheque.journal_du_mur (id serial PRIMARY KEY, jour date, entree text) ;
    
    UPDATE z_asgard.gestion_schema_usr
        SET editeur = 'g_consult'
        WHERE nom_schema = 'c_bibliotheque' ;
    
    ------ modification de l''éditeur ------
    UPDATE z_asgard.gestion_schema_usr
        SET editeur = 'g_admin_ext'
        WHERE nom_schema = 'c_bibliotheque' ;
    
    SELECT nspacl::text ~ ('g_admin_ext=U' || '[/]' || nspowner::regrole::text)
        INTO STRICT b
        FROM pg_catalog.pg_namespace
        WHERE nspname = 'c_bibliotheque' ;
        
    r := b ;
    
    SELECT relacl::text ~ ('g_admin_ext=[rwad]{4}' || '[/]' || relowner::regrole::text)
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'journal_du_mur' ;
        
    r := r AND b ;
    
    SELECT relacl::text ~ ('g_admin_ext=[rU]{2}' || '[/]' || relowner::regrole::text)
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'journal_du_mur_id_seq' ;
        
    r := r AND b ;
    
    SELECT NOT nspacl::text ~ 'g_consult'
        INTO STRICT b
        FROM pg_catalog.pg_namespace
        WHERE nspname = 'c_bibliotheque' ;
        
    r := r AND b ;
    
    SELECT NOT relacl::text ~ 'g_consult'
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'journal_du_mur' ;
        
    r := r AND b ;
    
    SELECT NOT relacl::text ~ 'g_consult'
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'journal_du_mur_id_seq' ;
        
    r := r AND b ;
    
    DROP SCHEMA c_bibliotheque CASCADE ;
    DELETE FROM z_asgard.gestion_schema_usr WHERE nom_schema = 'c_bibliotheque' ;
        
    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t017() IS 'ASGARD recette. TEST : modification de l''éditeur.' ;

-- FUNCTION: z_asgard_recette.t017b()

CREATE OR REPLACE FUNCTION z_asgard_recette.t017b()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
BEGIN

    CREATE ROLE "Admin EXT" ;
    CREATE ROLE "Consult" ;

    CREATE SCHEMA "c_Bibliothèque" ;
    CREATE TABLE "c_Bibliothèque"."Journal du mur" (id serial PRIMARY KEY, jour date, entree text) ;
    
    UPDATE z_asgard.gestion_schema_usr
        SET editeur = 'Consult'
        WHERE nom_schema = 'c_Bibliothèque' ;
    
    ------ modification de l''éditeur ------
    UPDATE z_asgard.gestion_schema_usr
        SET editeur = 'Admin EXT'
        WHERE nom_schema = 'c_Bibliothèque' ;
    
    SELECT array_to_string(nspacl, ',') ~ ('"Admin EXT"=U' || '[/]' || nspowner::regrole::text)
        INTO STRICT b
        FROM pg_catalog.pg_namespace
        WHERE nspname = 'c_Bibliothèque' ;
        
    r := b ;
    
    SELECT array_to_string(relacl, ',') ~ ('"Admin EXT"=[rwad]{4}' || '[/]' || z_asgard.asgard_role_trans_acl(relowner::regrole))
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'Journal du mur' ;
        
    r := r AND b ;
    
    SELECT array_to_string(relacl, ',') ~ ('"Admin EXT"=[rU]{2}' || '[/]' || z_asgard.asgard_role_trans_acl(relowner::regrole))
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'Journal du mur_id_seq' ;
        
    r := r AND b ;
    
    SELECT NOT array_to_string(nspacl, ',') ~ 'Consult'
        INTO STRICT b
        FROM pg_catalog.pg_namespace
        WHERE nspname = 'c_Bibliothèque' ;
        
    r := r AND b ;
    
    SELECT NOT array_to_string(relacl, ',') ~ 'Consult'
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'Journal du mur' ;
        
    r := r AND b ;
    
    SELECT NOT array_to_string(relacl, ',') ~ 'Consult'
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'Journal du mur_id_seq' ;
        
    r := r AND b ;
    
    DROP SCHEMA "c_Bibliothèque" CASCADE ;
    DELETE FROM z_asgard.gestion_schema_usr WHERE nom_schema = 'c_Bibliothèque' ;
    
    DROP ROLE "Consult" ;
    DROP ROLE "Admin EXT" ;
    
    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t017b() IS 'ASGARD recette. TEST : modification de l''éditeur.' ;


-- FUNCTION: z_asgard_recette.t018()

CREATE OR REPLACE FUNCTION z_asgard_recette.t018()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
BEGIN

    CREATE SCHEMA c_bibliotheque ;
    CREATE TABLE c_bibliotheque.journal_du_mur (id serial PRIMARY KEY, jour date, entree text) ;
    
    UPDATE z_asgard.gestion_schema_usr
        SET lecteur = 'g_consult'
        WHERE nom_schema = 'c_bibliotheque' ;
    
    ------ modification du lecteur ------
    UPDATE z_asgard.gestion_schema_usr
        SET lecteur = 'g_admin_ext'
        WHERE nom_schema = 'c_bibliotheque' ;
    
    SELECT nspacl::text ~ ('g_admin_ext=U' || '[/]' || nspowner::regrole::text)
        INTO STRICT b
        FROM pg_catalog.pg_namespace
        WHERE nspname = 'c_bibliotheque' ;
        
    r := b ;
    
    SELECT relacl::text ~ ('g_admin_ext=r' || '[/]' || relowner::regrole::text)
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'journal_du_mur' ;
        
    r := r AND b ;
    
    SELECT relacl::text ~ ('g_admin_ext=r' || '[/]' || relowner::regrole::text)
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'journal_du_mur_id_seq' ;
        
    r := r AND b ;
    
    SELECT NOT nspacl::text ~ 'g_consult'
        INTO STRICT b
        FROM pg_catalog.pg_namespace
        WHERE nspname = 'c_bibliotheque' ;
        
    r := r AND b ;
    
    SELECT NOT relacl::text ~ 'g_consult'
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'journal_du_mur' ;
        
    r := r AND b ;
    
    SELECT NOT relacl::text ~ 'g_consult'
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'journal_du_mur_id_seq' ;
        
    r := r AND b ;
    
    DROP SCHEMA c_bibliotheque CASCADE ;
    DELETE FROM z_asgard.gestion_schema_usr WHERE nom_schema = 'c_bibliotheque' ;
        
    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t018() IS 'ASGARD recette. TEST : modification du lecteur.' ;

-- FUNCTION: z_asgard_recette.t018b()

CREATE OR REPLACE FUNCTION z_asgard_recette.t018b()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
BEGIN

    CREATE ROLE "Admin EXT" ;
    CREATE ROLE "Consult" ;

    CREATE SCHEMA "c_Bibliothèque" ;
    CREATE TABLE "c_Bibliothèque"."Journal du mur" (id serial PRIMARY KEY, jour date, entree text) ;
    
    UPDATE z_asgard.gestion_schema_usr
        SET lecteur = 'Consult'
        WHERE nom_schema = 'c_Bibliothèque' ;
    
    ------ modification du lecteur ------
    UPDATE z_asgard.gestion_schema_usr
        SET lecteur = 'Admin EXT'
        WHERE nom_schema = 'c_Bibliothèque' ;
    
    SELECT array_to_string(nspacl, ',') ~ ('"Admin EXT"=U' || '[/]' || z_asgard.asgard_role_trans_acl(nspowner::regrole))
        INTO STRICT b
        FROM pg_catalog.pg_namespace
        WHERE nspname = 'c_Bibliothèque' ;
        
    r := b ;
    
    SELECT array_to_string(relacl, ',') ~ ('"Admin EXT"=r' || '[/]' || z_asgard.asgard_role_trans_acl(relowner::regrole))
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'Journal du mur' ;
        
    r := r AND b ;
    
    SELECT array_to_string(relacl, ',') ~ ('"Admin EXT"=r' || '[/]' || z_asgard.asgard_role_trans_acl(relowner::regrole))
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'Journal du mur_id_seq' ;
        
    r := r AND b ;
    
    SELECT NOT array_to_string(nspacl, ',') ~ 'Consult'
        INTO STRICT b
        FROM pg_catalog.pg_namespace
        WHERE nspname = 'c_Bibliothèque' ;
        
    r := r AND b ;
    
    SELECT NOT array_to_string(relacl, ',') ~ 'Consult'
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'Journal du mur' ;
        
    r := r AND b ;
    
    SELECT NOT array_to_string(relacl, ',') ~ 'Consult'
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'Journal du mur_id_seq' ;
        
    r := r AND b ;
    
    DROP SCHEMA "c_Bibliothèque" CASCADE ;
    DELETE FROM z_asgard.gestion_schema_usr WHERE nom_schema = 'c_Bibliothèque' ;
    
    DROP ROLE "Admin EXT" ;
    DROP ROLE "Consult" ;
    
    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t018b() IS 'ASGARD recette. TEST : modification du lecteur.' ;


-- FUNCTION: z_asgard_recette.t019()

CREATE OR REPLACE FUNCTION z_asgard_recette.t019()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
BEGIN

    CREATE SCHEMA c_bibliotheque ;
    CREATE TABLE c_bibliotheque.journal_du_mur (id serial PRIMARY KEY, jour date, entree text) ;
    
    UPDATE z_asgard.gestion_schema_usr
        SET editeur = 'g_consult'
        WHERE nom_schema = 'c_bibliotheque' ;
    
    ------ suppression de l''éditeur ------
    UPDATE z_asgard.gestion_schema_usr
        SET editeur = NULL
        WHERE nom_schema = 'c_bibliotheque' ;
    
    SELECT NOT nspacl::text ~ 'g_consult'
        INTO STRICT b
        FROM pg_catalog.pg_namespace
        WHERE nspname = 'c_bibliotheque' ;
        
    r := b ;
    
    SELECT NOT relacl::text ~ 'g_consult'
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'journal_du_mur' ;
        
    r := r AND b ;
    
    SELECT NOT relacl::text ~ 'g_consult'
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'journal_du_mur_id_seq' ;
        
    r := r AND b ;
    
    DROP SCHEMA c_bibliotheque CASCADE ;
    DELETE FROM z_asgard.gestion_schema_usr WHERE nom_schema = 'c_bibliotheque' ;
        
    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t019() IS 'ASGARD recette. TEST : suppression de l''éditeur.' ;

-- FUNCTION: z_asgard_recette.t019b()

CREATE OR REPLACE FUNCTION z_asgard_recette.t019b()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
BEGIN

    CREATE ROLE "Consult" ;

    CREATE SCHEMA "c_Bibliothèque" ;
    CREATE TABLE "c_Bibliothèque"."Journal du mur" (id serial PRIMARY KEY, jour date, entree text) ;
    
    UPDATE z_asgard.gestion_schema_usr
        SET editeur = 'Consult'
        WHERE nom_schema = 'c_Bibliothèque' ;
    
    ------ suppression de l''éditeur ------
    UPDATE z_asgard.gestion_schema_usr
        SET editeur = NULL
        WHERE nom_schema = 'c_Bibliothèque' ;
    
    SELECT NOT array_to_string(nspacl, ',') ~ 'Consult'
        INTO STRICT b
        FROM pg_catalog.pg_namespace
        WHERE nspname = 'c_Bibliothèque' ;
        
    r := b ;
    
    SELECT NOT array_to_string(relacl, ',') ~ 'Consult'
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'Journal du mur' ;
        
    r := r AND b ;
    
    SELECT NOT array_to_string(relacl, ',') ~ 'Consult'
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'Journal du mur_id_seq' ;
        
    r := r AND b ;
    
    DROP SCHEMA "c_Bibliothèque" CASCADE ;
    DELETE FROM z_asgard.gestion_schema_usr WHERE nom_schema = 'c_Bibliothèque' ;
    
    DROP ROLE "Consult" ;
        
    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t019b() IS 'ASGARD recette. TEST : suppression de l''éditeur.' ;


-- FUNCTION: z_asgard_recette.t020()

CREATE OR REPLACE FUNCTION z_asgard_recette.t020()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
BEGIN

    CREATE SCHEMA c_bibliotheque ;
    CREATE TABLE c_bibliotheque.journal_du_mur (id serial PRIMARY KEY, jour date, entree text) ;
    
    UPDATE z_asgard.gestion_schema_usr
        SET lecteur = 'g_consult'
        WHERE nom_schema = 'c_bibliotheque' ;
    
    ------ suppression du lecteur ------
    UPDATE z_asgard.gestion_schema_usr
        SET lecteur = NULL
        WHERE nom_schema = 'c_bibliotheque' ;
    
    SELECT NOT nspacl::text ~ 'g_consult'
        INTO STRICT b
        FROM pg_catalog.pg_namespace
        WHERE nspname = 'c_bibliotheque' ;
        
    r := b ;
    
    SELECT NOT relacl::text ~ 'g_consult'
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'journal_du_mur' ;
        
    r := r AND b ;
    
    SELECT NOT relacl::text ~ 'g_consult'
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'journal_du_mur_id_seq' ;
        
    r := r AND b ;
    
    DROP SCHEMA c_bibliotheque CASCADE ;
    DELETE FROM z_asgard.gestion_schema_usr WHERE nom_schema = 'c_bibliotheque' ;
        
    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t020() IS 'ASGARD recette. TEST : suppression du lecteur.' ;

-- FUNCTION: z_asgard_recette.t020b()

CREATE OR REPLACE FUNCTION z_asgard_recette.t020b()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
BEGIN

    CREATE ROLE "Consult" ;

    CREATE SCHEMA "c_Bibliothèque" ;
    CREATE TABLE "c_Bibliothèque"."Journal du mur" (id serial PRIMARY KEY, jour date, entree text) ;
    
    UPDATE z_asgard.gestion_schema_usr
        SET lecteur = 'Consult'
        WHERE nom_schema = 'c_Bibliothèque' ;
    
    ------ suppression du lecteur ------
    UPDATE z_asgard.gestion_schema_usr
        SET lecteur = NULL
        WHERE nom_schema = 'c_Bibliothèque' ;
    
    SELECT NOT array_to_string(nspacl, ',') ~ 'Consult'
        INTO STRICT b
        FROM pg_catalog.pg_namespace
        WHERE nspname = 'c_Bibliothèque' ;
        
    r := b ;
    
    SELECT NOT array_to_string(relacl, ',') ~ 'Consult'
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'Journal du mur' ;
        
    r := r AND b ;
    
    SELECT NOT array_to_string(relacl, ',') ~ 'Consult'
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'Journal du mur_id_seq' ;
        
    r := r AND b ;
    
    DROP SCHEMA "c_Bibliothèque" CASCADE ;
    DELETE FROM z_asgard.gestion_schema_usr WHERE nom_schema = 'c_Bibliothèque' ;
    
    DROP ROLE "Consult" ;
    
    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t020b() IS 'ASGARD recette. TEST : suppression du lecteur.' ;


-- FUNCTION: z_asgard_recette.t021()

CREATE OR REPLACE FUNCTION z_asgard_recette.t021()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
BEGIN

    CREATE SCHEMA c_bibliotheque ;
    CREATE TABLE c_bibliotheque.journal_du_mur (id serial PRIMARY KEY, jour date, entree text) ;
    
    UPDATE z_asgard.gestion_schema_usr
        SET editeur = 'g_consult'
        WHERE nom_schema = 'c_bibliotheque' ;
        
    GRANT CREATE ON SCHEMA c_bibliotheque TO g_consult ;
    REVOKE DELETE ON TABLE c_bibliotheque.journal_du_mur FROM g_consult ;
    REVOKE USAGE ON SEQUENCE c_bibliotheque.journal_du_mur_id_seq FROM g_consult ;
    
    ------ modification de l''éditeur ------
    UPDATE z_asgard.gestion_schema_usr
        SET editeur = 'g_admin_ext'
        WHERE nom_schema = 'c_bibliotheque' ;
    
    SELECT nspacl::text ~ ('g_admin_ext=[UC]{2}' || '[/]' || nspowner::regrole::text)
        INTO STRICT b
        FROM pg_catalog.pg_namespace
        WHERE nspname = 'c_bibliotheque' ;
        
    r := b ;
    
    SELECT relacl::text ~ ('g_admin_ext=[rwa]{3}' || '[/]' || relowner::regrole::text)
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'journal_du_mur' ;
        
    r := r AND b ;
    
    SELECT relacl::text ~ ('g_admin_ext=r' || '[/]' || relowner::regrole::text)
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'journal_du_mur_id_seq' ;
        
    r := r AND b ;
    
    DROP SCHEMA c_bibliotheque CASCADE ;
    DELETE FROM z_asgard.gestion_schema_usr WHERE nom_schema = 'c_bibliotheque' ;
        
    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t021() IS 'ASGARD recette. TEST : transmission des modifications manuelles (éditeur).' ;

-- FUNCTION: z_asgard_recette.t021b()

CREATE OR REPLACE FUNCTION z_asgard_recette.t021b()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
BEGIN

    CREATE ROLE "Consult" ;
    CREATE ROLE "Admin EXT" ;

    CREATE SCHEMA "c_Bibliothèque" ;
    CREATE TABLE "c_Bibliothèque"."Journal du mur" (id serial PRIMARY KEY, jour date, entree text) ;
    
    UPDATE z_asgard.gestion_schema_usr
        SET editeur = 'Consult'
        WHERE nom_schema = 'c_Bibliothèque' ;
        
    GRANT CREATE ON SCHEMA "c_Bibliothèque" TO "Consult" ;
    REVOKE DELETE ON TABLE "c_Bibliothèque"."Journal du mur" FROM "Consult" ;
    REVOKE USAGE ON SEQUENCE "c_Bibliothèque"."Journal du mur_id_seq" FROM "Consult" ;
    
    ------ modification de l''éditeur ------
    UPDATE z_asgard.gestion_schema_usr
        SET editeur = 'Admin EXT'
        WHERE nom_schema = 'c_Bibliothèque' ;
    
    SELECT array_to_string(nspacl, ',') ~ ('"Admin EXT"=[UC]{2}' || '[/]' || z_asgard.asgard_role_trans_acl(nspowner::regrole))
        INTO STRICT b
        FROM pg_catalog.pg_namespace
        WHERE nspname = 'c_Bibliothèque' ;
        
    r := b ;
    
    SELECT array_to_string(relacl, ',') ~ ('"Admin EXT"=[rwa]{3}' || '[/]' || z_asgard.asgard_role_trans_acl(relowner::regrole))
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'Journal du mur' ;
        
    r := r AND b ;
    
    SELECT array_to_string(relacl, ',') ~ ('"Admin EXT"=r' || '[/]' || z_asgard.asgard_role_trans_acl(relowner::regrole))
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'Journal du mur_id_seq' ;
        
    r := r AND b ;
    
    DROP SCHEMA "c_Bibliothèque" CASCADE ;
    DELETE FROM z_asgard.gestion_schema_usr WHERE nom_schema = 'c_Bibliothèque' ;
    
    DROP ROLE "Consult" ;
    DROP ROLE "Admin EXT" ;
    
    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t021b() IS 'ASGARD recette. TEST : transmission des modifications manuelles (éditeur).' ;


-- FUNCTION: z_asgard_recette.t022()

CREATE OR REPLACE FUNCTION z_asgard_recette.t022()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
BEGIN

    CREATE SCHEMA c_bibliotheque ;
    CREATE TABLE c_bibliotheque.journal_du_mur (id serial PRIMARY KEY, jour date, entree text) ;
    
    UPDATE z_asgard.gestion_schema_usr
        SET lecteur = 'g_consult'
        WHERE nom_schema = 'c_bibliotheque' ;
        
    GRANT CREATE ON SCHEMA c_bibliotheque TO g_consult ;
    GRANT UPDATE ON TABLE c_bibliotheque.journal_du_mur TO g_consult ;
    GRANT USAGE ON SEQUENCE c_bibliotheque.journal_du_mur_id_seq TO g_consult ;
    
    ------ modification du lecteur ------
    UPDATE z_asgard.gestion_schema_usr
        SET lecteur = 'g_admin_ext'
        WHERE nom_schema = 'c_bibliotheque' ;
    
    SELECT nspacl::text ~ ('g_admin_ext=[UC]{2}' || '[/]' || nspowner::regrole::text)
        INTO STRICT b
        FROM pg_catalog.pg_namespace
        WHERE nspname = 'c_bibliotheque' ;
        
    r := b ;
    
    SELECT relacl::text ~ ('g_admin_ext=[rw]{2}' || '[/]' || relowner::regrole::text)
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'journal_du_mur' ;
        
    r := r AND b ;
    
    SELECT relacl::text ~ ('g_admin_ext=[rU]{2}' || '[/]' || relowner::regrole::text)
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'journal_du_mur_id_seq' ;
        
    r := r AND b ;
    
    DROP SCHEMA c_bibliotheque CASCADE ;
    DELETE FROM z_asgard.gestion_schema_usr WHERE nom_schema = 'c_bibliotheque' ;
        
    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t022() IS 'ASGARD recette. TEST : transmission des modifications manuelles (lecteur).' ;

-- FUNCTION: z_asgard_recette.t022b()

CREATE OR REPLACE FUNCTION z_asgard_recette.t022b()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
BEGIN

    CREATE ROLE "Consult" ;
    CREATE ROLE "Admin EXT" ;

    CREATE SCHEMA "c_Bibliothèque" ;
    CREATE TABLE "c_Bibliothèque"."Journal du mur" (id serial PRIMARY KEY, jour date, entree text) ;
    
    UPDATE z_asgard.gestion_schema_usr
        SET lecteur = 'Consult'
        WHERE nom_schema = 'c_Bibliothèque' ;
        
    GRANT CREATE ON SCHEMA "c_Bibliothèque" TO "Consult" ;
    GRANT UPDATE ON TABLE "c_Bibliothèque"."Journal du mur" TO "Consult" ;
    GRANT USAGE ON SEQUENCE "c_Bibliothèque"."Journal du mur_id_seq" TO "Consult" ;
    
    ------ modification du lecteur ------
    UPDATE z_asgard.gestion_schema_usr
        SET lecteur = 'Admin EXT'
        WHERE nom_schema = 'c_Bibliothèque' ;
    
    SELECT array_to_string(nspacl, ',') ~ ('"Admin EXT"=[UC]{2}' || '[/]' || z_asgard.asgard_role_trans_acl(nspowner::regrole))
        INTO STRICT b
        FROM pg_catalog.pg_namespace
        WHERE nspname = 'c_Bibliothèque' ;
        
    r := b ;
    
    SELECT array_to_string(relacl, ',') ~ ('"Admin EXT"=[rw]{2}' || '[/]' || z_asgard.asgard_role_trans_acl(relowner::regrole))
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'Journal du mur' ;
        
    r := r AND b ;
    
    SELECT array_to_string(relacl, ',') ~ ('"Admin EXT"=[rU]{2}' || '[/]' || z_asgard.asgard_role_trans_acl(relowner::regrole))
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'Journal du mur_id_seq' ;
        
    r := r AND b ;
    
    DROP SCHEMA "c_Bibliothèque" CASCADE ;
    DELETE FROM z_asgard.gestion_schema_usr WHERE nom_schema = 'c_Bibliothèque' ;
    
    DROP ROLE "Consult" ;
    DROP ROLE "Admin EXT" ;
    
    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t022b() IS 'ASGARD recette. TEST : transmission des modifications manuelles (lecteur).' ;


-- FUNCTION: z_asgard_recette.t023()

CREATE OR REPLACE FUNCTION z_asgard_recette.t023()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
BEGIN

    CREATE SCHEMA c_bibliotheque ;
    CREATE TABLE c_bibliotheque.journal_du_mur (id serial PRIMARY KEY, jour date, entree text) ;
    
    ------ désignation de l''éditeur public ------
    UPDATE z_asgard.gestion_schema_usr
        SET editeur = 'public'
        WHERE nom_schema = 'c_bibliotheque' ;
        
    CREATE TABLE c_bibliotheque.journal_du_mur_bis (id serial PRIMARY KEY, jour date, entree text) ;
    
    SELECT nspacl::text ~ ('^(.*,)?=U' || '[/]' || nspowner::regrole::text)
        INTO STRICT b
        FROM pg_catalog.pg_namespace
        WHERE nspname = 'c_bibliotheque' ;
        
    r := b ;
    
    SELECT relacl::text ~ ('^(.*,)?=[rwad]{4}' || '[/]' || relowner::regrole::text)
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'journal_du_mur' ;
        
    r := r AND b ;
    
    SELECT relacl::text ~ ('^(.*,)?=[rU]{2}' || '[/]' || relowner::regrole::text)
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'journal_du_mur_id_seq' ;
        
    r := r AND b ;
    
    SELECT relacl::text ~ ('^(.*,)?=[rwad]{4}' || '[/]' || relowner::regrole::text)
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'journal_du_mur_bis' ;
        
    r := r AND b ;
    
    SELECT relacl::text ~ ('^(.*,)?=[rU]{2}' || '[/]' || relowner::regrole::text)
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'journal_du_mur_bis_id_seq' ;
        
    r := r AND b ;

    DROP SCHEMA c_bibliotheque CASCADE ;
    DELETE FROM z_asgard.gestion_schema_usr WHERE nom_schema = 'c_bibliotheque' ;
        
    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t023() IS 'ASGARD recette. TEST : désignation d''un éditeur public.' ;

-- FUNCTION: z_asgard_recette.t023b()

CREATE OR REPLACE FUNCTION z_asgard_recette.t023b()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
BEGIN

    CREATE SCHEMA "c_Bibliothèque" ;
    CREATE TABLE "c_Bibliothèque"."Journal du mur" (id serial PRIMARY KEY, jour date, entree text) ;
    
    ------ désignation de l''éditeur public ------
    UPDATE z_asgard.gestion_schema_usr
        SET editeur = 'public'
        WHERE nom_schema = 'c_Bibliothèque' ;
        
    CREATE TABLE "c_Bibliothèque"."Journal du mur_bis" (id serial PRIMARY KEY, jour date, entree text) ;
    
    SELECT array_to_string(nspacl, ',') ~ ('^(.*,)?=U' || '[/]' || z_asgard.asgard_role_trans_acl(nspowner::regrole))
        INTO STRICT b
        FROM pg_catalog.pg_namespace
        WHERE nspname = 'c_Bibliothèque' ;
        
    r := b ;
    
    SELECT array_to_string(relacl, ',') ~ ('^(.*,)?=[rwad]{4}' || '[/]' || z_asgard.asgard_role_trans_acl(relowner::regrole))
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'Journal du mur' ;
        
    r := r AND b ;
    
    SELECT array_to_string(relacl, ',') ~ ('^(.*,)?=[rU]{2}' || '[/]' || z_asgard.asgard_role_trans_acl(relowner::regrole))
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'Journal du mur_id_seq' ;
        
    r := r AND b ;
    
    SELECT array_to_string(relacl, ',') ~ ('^(.*,)?=[rwad]{4}' || '[/]' || z_asgard.asgard_role_trans_acl(relowner::regrole))
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'Journal du mur_bis' ;
        
    r := r AND b ;
    
    SELECT array_to_string(relacl, ',') ~ ('^(.*,)?=[rU]{2}' || '[/]' || z_asgard.asgard_role_trans_acl(relowner::regrole))
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'Journal du mur_bis_id_seq' ;
        
    r := r AND b ;

    DROP SCHEMA "c_Bibliothèque" CASCADE ;
    DELETE FROM z_asgard.gestion_schema_usr WHERE nom_schema = 'c_Bibliothèque' ;
        
    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t023b() IS 'ASGARD recette. TEST : désignation d''un éditeur public.' ;



-- FUNCTION: z_asgard_recette.t024()

CREATE OR REPLACE FUNCTION z_asgard_recette.t024()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
BEGIN

    CREATE SCHEMA c_bibliotheque ;
    CREATE TABLE c_bibliotheque.journal_du_mur (id serial PRIMARY KEY, jour date, entree text) ;
    
    ------ désignation du lecteur public ------
    UPDATE z_asgard.gestion_schema_usr
        SET lecteur = 'public'
        WHERE nom_schema = 'c_bibliotheque' ;
        
    CREATE TABLE c_bibliotheque.journal_du_mur_bis (id serial PRIMARY KEY, jour date, entree text) ;
    
    SELECT nspacl::text ~ ('^(.*,)?=U' || '[/]' || nspowner::regrole::text)
        INTO STRICT b
        FROM pg_catalog.pg_namespace
        WHERE nspname = 'c_bibliotheque' ;
        
    r := b ;
    
    SELECT relacl::text ~ ('^(.*,)?=r' || '[/]' || relowner::regrole::text)
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'journal_du_mur' ;
        
    r := r AND b ;
    
    SELECT relacl::text ~ ('^(.*,)?=r' || '[/]' || relowner::regrole::text)
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'journal_du_mur_id_seq' ;
        
    r := r AND b ;
    
    SELECT relacl::text ~ ('^(.*,)?=r' || '[/]' || relowner::regrole::text)
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'journal_du_mur_bis' ;
        
    r := r AND b ;
    
    SELECT relacl::text ~ ('^(.*,)?=r' || '[/]' || relowner::regrole::text)
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'journal_du_mur_bis_id_seq' ;
        
    r := r AND b ;

    DROP SCHEMA c_bibliotheque CASCADE ;
    DELETE FROM z_asgard.gestion_schema_usr WHERE nom_schema = 'c_bibliotheque' ;
        
    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t024() IS 'ASGARD recette. TEST : désignation d''un lecteur public.' ;

-- FUNCTION: z_asgard_recette.t024b()

CREATE OR REPLACE FUNCTION z_asgard_recette.t024b()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
BEGIN

    CREATE SCHEMA "c_Bibliothèque" ;
    CREATE TABLE "c_Bibliothèque"."Journal du mur" (id serial PRIMARY KEY, jour date, entree text) ;
    
    ------ désignation du lecteur public ------
    UPDATE z_asgard.gestion_schema_usr
        SET lecteur = 'public'
        WHERE nom_schema = 'c_Bibliothèque' ;
        
    CREATE TABLE "c_Bibliothèque"."Journal du mur_bis" (id serial PRIMARY KEY, jour date, entree text) ;
    
    SELECT array_to_string(nspacl, ',') ~ ('^(.*,)?=U' || '[/]' || z_asgard.asgard_role_trans_acl(nspowner::regrole))
        INTO STRICT b
        FROM pg_catalog.pg_namespace
        WHERE nspname = 'c_Bibliothèque' ;
        
    r := b ;
    
    SELECT array_to_string(relacl, ',') ~ ('^(.*,)?=r' || '[/]' || z_asgard.asgard_role_trans_acl(relowner::regrole))
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'Journal du mur' ;
        
    r := r AND b ;
    
    SELECT array_to_string(relacl, ',') ~ ('^(.*,)?=r' || '[/]' || z_asgard.asgard_role_trans_acl(relowner::regrole))
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'Journal du mur_id_seq' ;
        
    r := r AND b ;
    
    SELECT array_to_string(relacl, ',') ~ ('^(.*,)?=r' || '[/]' || z_asgard.asgard_role_trans_acl(relowner::regrole))
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'Journal du mur_bis' ;
        
    r := r AND b ;
    
    SELECT array_to_string(relacl, ',') ~ ('^(.*,)?=r' || '[/]' || z_asgard.asgard_role_trans_acl(relowner::regrole))
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'Journal du mur_bis_id_seq' ;
        
    r := r AND b ;

    DROP SCHEMA "c_Bibliothèque" CASCADE ;
    DELETE FROM z_asgard.gestion_schema_usr WHERE nom_schema = 'c_Bibliothèque' ;
        
    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t024b() IS 'ASGARD recette. TEST : désignation d''un lecteur public.' ;



-- FUNCTION: z_asgard_recette.t025()

CREATE OR REPLACE FUNCTION z_asgard_recette.t025()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
BEGIN

    CREATE SCHEMA c_bibliotheque ;
    CREATE TABLE c_bibliotheque.journal_du_mur (id serial PRIMARY KEY, jour date, entree text) ;
    
    UPDATE z_asgard.gestion_schema_usr
        SET editeur = 'public'
        WHERE nom_schema = 'c_bibliotheque' ;
    
    ------ suppression de l''éditeur public ------
    UPDATE z_asgard.gestion_schema_usr
        SET editeur = NULL
        WHERE nom_schema = 'c_bibliotheque' ;
    
    SELECT NOT nspacl::text ~ '^(.*,)?='
        INTO STRICT b
        FROM pg_catalog.pg_namespace
        WHERE nspname = 'c_bibliotheque' ;
        
    r := b ;
    
    SELECT NOT relacl::text ~ '^(.*,)?='
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'journal_du_mur' ;
        
    r := r AND b ;
    
    SELECT NOT relacl::text ~ '^(.*,)?='
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'journal_du_mur_id_seq' ;
        
    r := r AND b ;
    
    DROP SCHEMA c_bibliotheque CASCADE ;
    DELETE FROM z_asgard.gestion_schema_usr WHERE nom_schema = 'c_bibliotheque' ;
        
    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t025() IS 'ASGARD recette. TEST : suppression de l''éditeur public.' ;

-- FUNCTION: z_asgard_recette.t025b()

CREATE OR REPLACE FUNCTION z_asgard_recette.t025b()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
BEGIN

    CREATE SCHEMA "c_Bibliothèque" ;
    CREATE TABLE "c_Bibliothèque"."Journal du mur" (id serial PRIMARY KEY, jour date, entree text) ;
    
    UPDATE z_asgard.gestion_schema_usr
        SET editeur = 'public'
        WHERE nom_schema = 'c_Bibliothèque' ;
    
    ------ suppression de l''éditeur public ------
    UPDATE z_asgard.gestion_schema_usr
        SET editeur = NULL
        WHERE nom_schema = 'c_Bibliothèque' ;
    
    SELECT NOT array_to_string(nspacl, ',') ~ '^(.*,)?='
        INTO STRICT b
        FROM pg_catalog.pg_namespace
        WHERE nspname = 'c_Bibliothèque' ;
        
    r := b ;
    
    SELECT NOT array_to_string(relacl, ',') ~ '^(.*,)?='
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'Journal du mur' ;
        
    r := r AND b ;
    
    SELECT NOT array_to_string(relacl, ',') ~ '^(.*,)?='
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'Journal du mur_id_seq' ;
        
    r := r AND b ;
    
    DROP SCHEMA "c_Bibliothèque" CASCADE ;
    DELETE FROM z_asgard.gestion_schema_usr WHERE nom_schema = 'c_Bibliothèque' ;
        
    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t025b() IS 'ASGARD recette. TEST : suppression de l''éditeur public.' ;


-- FUNCTION: z_asgard_recette.t026()

CREATE OR REPLACE FUNCTION z_asgard_recette.t026()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
BEGIN

    CREATE SCHEMA c_bibliotheque ;
    CREATE TABLE c_bibliotheque.journal_du_mur (id serial PRIMARY KEY, jour date, entree text) ;
    
    UPDATE z_asgard.gestion_schema_usr
        SET lecteur = 'public'
        WHERE nom_schema = 'c_bibliotheque' ;
    
    ------ suppression du lecteur public ------
    UPDATE z_asgard.gestion_schema_usr
        SET lecteur = NULL
        WHERE nom_schema = 'c_bibliotheque' ;
    
    SELECT NOT nspacl::text ~ '^(.*,)?='
        INTO STRICT b
        FROM pg_catalog.pg_namespace
        WHERE nspname = 'c_bibliotheque' ;
        
    r := b ;
    
    SELECT NOT relacl::text ~ '^(.*,)?='
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'journal_du_mur' ;
        
    r := r AND b ;
    
    SELECT NOT relacl::text ~ '^(.*,)?='
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'journal_du_mur_id_seq' ;
        
    r := r AND b ;
    
    DROP SCHEMA c_bibliotheque CASCADE ;
    DELETE FROM z_asgard.gestion_schema_usr WHERE nom_schema = 'c_bibliotheque' ;
        
    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t026() IS 'ASGARD recette. TEST : suppression du lecteur public.' ;

-- FUNCTION: z_asgard_recette.t026b()

CREATE OR REPLACE FUNCTION z_asgard_recette.t026b()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
BEGIN

    CREATE SCHEMA "c_Bibliothèque" ;
    CREATE TABLE "c_Bibliothèque"."Journal du mur" (id serial PRIMARY KEY, jour date, entree text) ;
    
    UPDATE z_asgard.gestion_schema_usr
        SET lecteur = 'public'
        WHERE nom_schema = 'c_Bibliothèque' ;
    
    ------ suppression du lecteur public ------
    UPDATE z_asgard.gestion_schema_usr
        SET lecteur = NULL
        WHERE nom_schema = 'c_Bibliothèque' ;
    
    SELECT NOT array_to_string(nspacl, ',') ~ '^(.*,)?='
        INTO STRICT b
        FROM pg_catalog.pg_namespace
        WHERE nspname = 'c_Bibliothèque' ;
        
    r := b ;
    
    SELECT NOT array_to_string(relacl, ',') ~ '^(.*,)?='
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'Journal du mur' ;
        
    r := r AND b ;
    
    SELECT NOT array_to_string(relacl, ',') ~ '^(.*,)?='
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'Journal du mur_id_seq' ;
        
    r := r AND b ;
    
    DROP SCHEMA "c_Bibliothèque" CASCADE ;
    DELETE FROM z_asgard.gestion_schema_usr WHERE nom_schema = 'c_Bibliothèque' ;
        
    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t026b() IS 'ASGARD recette. TEST : suppression du lecteur public.' ;


-- FUNCTION: z_asgard_recette.t027()

CREATE OR REPLACE FUNCTION z_asgard_recette.t027()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
BEGIN

    CREATE SCHEMA c_bibliotheque ;
    CREATE TABLE c_bibliotheque.journal_du_mur (id serial PRIMARY KEY, jour date, entree text) ;
    
    UPDATE z_asgard.gestion_schema_usr
        SET editeur = 'public'
        WHERE nom_schema = 'c_bibliotheque' ;
        
    GRANT CREATE ON SCHEMA c_bibliotheque TO public ;
    REVOKE DELETE ON TABLE c_bibliotheque.journal_du_mur FROM public ;
    REVOKE USAGE ON SEQUENCE c_bibliotheque.journal_du_mur_id_seq FROM public ;
    
    ------ modification de l''éditeur (depuis public) ------
    UPDATE z_asgard.gestion_schema_usr
        SET editeur = 'g_admin_ext'
        WHERE nom_schema = 'c_bibliotheque' ;
    
    SELECT nspacl::text ~ ('g_admin_ext=[UC]{2}' || '[/]' || nspowner::regrole::text)
        INTO STRICT b
        FROM pg_catalog.pg_namespace
        WHERE nspname = 'c_bibliotheque' ;
        
    r := b ;
    
    SELECT relacl::text ~ ('g_admin_ext=[rwa]{3}' || '[/]' || relowner::regrole::text)
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'journal_du_mur' ;
        
    r := r AND b ;
    
    SELECT relacl::text ~ ('g_admin_ext=r' || '[/]' || relowner::regrole::text)
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'journal_du_mur_id_seq' ;
        
    r := r AND b ;
    
    
    ------ modification de l''éditeur (vers public) ------
    UPDATE z_asgard.gestion_schema_usr
        SET editeur = 'public'
        WHERE nom_schema = 'c_bibliotheque' ;
    
    SELECT nspacl::text ~ ('^(.*,)?=[UC]{2}' || '[/]' || nspowner::regrole::text)
        INTO STRICT b
        FROM pg_catalog.pg_namespace
        WHERE nspname = 'c_bibliotheque' ;
        
    r := r AND b ;
    
    SELECT relacl::text ~ ('^(.*,)?=[rwa]{3}' || '[/]' || relowner::regrole::text)
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'journal_du_mur' ;
        
    r := r AND b ;
    
    SELECT relacl::text ~ ('^(.*,)?=r' || '[/]' || relowner::regrole::text)
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'journal_du_mur_id_seq' ;
        
    r := r AND b ;
    
    DROP SCHEMA c_bibliotheque CASCADE ;
    DELETE FROM z_asgard.gestion_schema_usr WHERE nom_schema = 'c_bibliotheque' ;
        
    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t027() IS 'ASGARD recette. TEST : transmission des modifications manuelles (éditeur public).' ;

-- FUNCTION: z_asgard_recette.t027b()

CREATE OR REPLACE FUNCTION z_asgard_recette.t027b()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
BEGIN

    CREATE ROLE "Admin EXT" ;

    CREATE SCHEMA "c_Bibliothèque" ;
    CREATE TABLE "c_Bibliothèque"."Journal du mur" (id serial PRIMARY KEY, jour date, entree text) ;
    
    UPDATE z_asgard.gestion_schema_usr
        SET editeur = 'public'
        WHERE nom_schema = 'c_Bibliothèque' ;
        
    GRANT CREATE ON SCHEMA "c_Bibliothèque" TO public ;
    REVOKE DELETE ON TABLE "c_Bibliothèque"."Journal du mur" FROM public ;
    REVOKE USAGE ON SEQUENCE "c_Bibliothèque"."Journal du mur_id_seq" FROM public ;
    
    ------ modification de l''éditeur (depuis public) ------
    UPDATE z_asgard.gestion_schema_usr
        SET editeur = 'Admin EXT'
        WHERE nom_schema = 'c_Bibliothèque' ;
    
    SELECT array_to_string(nspacl, ',') ~ ('"Admin EXT"=[UC]{2}' || '[/]' || z_asgard.asgard_role_trans_acl(nspowner::regrole))
        INTO STRICT b
        FROM pg_catalog.pg_namespace
        WHERE nspname = 'c_Bibliothèque' ;
        
    r := b ;
    
    SELECT array_to_string(relacl, ',') ~ ('"Admin EXT"=[rwa]{3}' || '[/]' || z_asgard.asgard_role_trans_acl(relowner::regrole))
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'Journal du mur' ;
        
    r := r AND b ;
    
    SELECT array_to_string(relacl, ',') ~ ('"Admin EXT"=r' || '[/]' || z_asgard.asgard_role_trans_acl(relowner::regrole))
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'Journal du mur_id_seq' ;
        
    r := r AND b ;
    
    
    ------ modification de l''éditeur (vers public) ------
    UPDATE z_asgard.gestion_schema_usr
        SET editeur = 'public'
        WHERE nom_schema = 'c_Bibliothèque' ;
    
    SELECT array_to_string(nspacl, ',') ~ ('^(.*,)?=[UC]{2}' || '[/]' || z_asgard.asgard_role_trans_acl(nspowner::regrole))
        INTO STRICT b
        FROM pg_catalog.pg_namespace
        WHERE nspname = 'c_Bibliothèque' ;
        
    r := r AND b ;
    
    SELECT array_to_string(relacl, ',') ~ ('^(.*,)?=[rwa]{3}' || '[/]' || z_asgard.asgard_role_trans_acl(relowner::regrole))
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'Journal du mur' ;
        
    r := r AND b ;
    
    SELECT array_to_string(relacl, ',') ~ ('^(.*,)?=r' || '[/]' || z_asgard.asgard_role_trans_acl(relowner::regrole))
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'Journal du mur_id_seq' ;
        
    r := r AND b ;
    
    DROP SCHEMA "c_Bibliothèque" CASCADE ;
    DELETE FROM z_asgard.gestion_schema_usr WHERE nom_schema = 'c_Bibliothèque' ;
    
    DROP ROLE "Admin EXT" ;
        
    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t027b() IS 'ASGARD recette. TEST : transmission des modifications manuelles (éditeur public).' ;



-- FUNCTION: z_asgard_recette.t028()

CREATE OR REPLACE FUNCTION z_asgard_recette.t028()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
BEGIN

    CREATE SCHEMA c_bibliotheque ;
    CREATE TABLE c_bibliotheque.journal_du_mur (id serial PRIMARY KEY, jour date, entree text) ;
    
    UPDATE z_asgard.gestion_schema_usr
        SET lecteur = 'public'
        WHERE nom_schema = 'c_bibliotheque' ;
        
    GRANT CREATE ON SCHEMA c_bibliotheque TO public ;
    GRANT UPDATE ON TABLE c_bibliotheque.journal_du_mur TO public ;
    GRANT USAGE ON SEQUENCE c_bibliotheque.journal_du_mur_id_seq TO public ;
    
    ------ modification du lecteur (depuis public) ------
    UPDATE z_asgard.gestion_schema_usr
        SET lecteur = 'g_admin_ext'
        WHERE nom_schema = 'c_bibliotheque' ;
    
    SELECT nspacl::text ~ ('g_admin_ext=[UC]{2}' || '[/]' || nspowner::regrole::text)
        INTO STRICT b
        FROM pg_catalog.pg_namespace
        WHERE nspname = 'c_bibliotheque' ;
        
    r := b ;
    
    SELECT relacl::text ~ ('g_admin_ext=[rw]{2}' || '[/]' || relowner::regrole::text)
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'journal_du_mur' ;
        
    r := r AND b ;
    
    SELECT relacl::text ~ ('g_admin_ext=[rU]{2}' || '[/]' || relowner::regrole::text)
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'journal_du_mur_id_seq' ;
        
    r := r AND b ;
    
    ------ modification du lecteur (vers public) ------
    UPDATE z_asgard.gestion_schema_usr
        SET lecteur = 'public'
        WHERE nom_schema = 'c_bibliotheque' ;
    
    SELECT nspacl::text ~ ('^(.*,)?=[UC]{2}' || '[/]' || nspowner::regrole::text)
        INTO STRICT b
        FROM pg_catalog.pg_namespace
        WHERE nspname = 'c_bibliotheque' ;
        
    r := r AND b ;
    
    SELECT relacl::text ~ ('^(.*,)?=[rw]{2}' || '[/]' || relowner::regrole::text)
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'journal_du_mur' ;
        
    r := r AND b ;
    
    SELECT relacl::text ~ ('^(.*,)?=[rU]{2}' || '[/]' || relowner::regrole::text)
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'journal_du_mur_id_seq' ;
        
    r := r AND b ;
    
    
    DROP SCHEMA c_bibliotheque CASCADE ;
    DELETE FROM z_asgard.gestion_schema_usr WHERE nom_schema = 'c_bibliotheque' ;
        
    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t028() IS 'ASGARD recette. TEST : transmission des modifications manuelles (lecteur public).' ;

-- FUNCTION: z_asgard_recette.t028b()

CREATE OR REPLACE FUNCTION z_asgard_recette.t028b()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
BEGIN

    CREATE ROLE "Admin EXT" ;

    CREATE SCHEMA "c_Bibliothèque" ;
    CREATE TABLE "c_Bibliothèque"."Journal du mur" (id serial PRIMARY KEY, jour date, entree text) ;
    
    UPDATE z_asgard.gestion_schema_usr
        SET lecteur = 'public'
        WHERE nom_schema = 'c_Bibliothèque' ;
        
    GRANT CREATE ON SCHEMA "c_Bibliothèque" TO public ;
    GRANT UPDATE ON TABLE "c_Bibliothèque"."Journal du mur" TO public ;
    GRANT USAGE ON SEQUENCE "c_Bibliothèque"."Journal du mur_id_seq" TO public ;
    
    ------ modification du lecteur (depuis public) ------
    UPDATE z_asgard.gestion_schema_usr
        SET lecteur = 'Admin EXT'
        WHERE nom_schema = 'c_Bibliothèque' ;
    
    SELECT array_to_string(nspacl, ',') ~ ('"Admin EXT"=[UC]{2}' || '[/]' || z_asgard.asgard_role_trans_acl(nspowner::regrole))
        INTO STRICT b
        FROM pg_catalog.pg_namespace
        WHERE nspname = 'c_Bibliothèque' ;
        
    r := b ;
    
    SELECT array_to_string(relacl, ',') ~ ('"Admin EXT"=[rw]{2}' || '[/]' || z_asgard.asgard_role_trans_acl(relowner::regrole))
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'Journal du mur' ;
        
    r := r AND b ;
    
    SELECT array_to_string(relacl, ',') ~ ('"Admin EXT"=[rU]{2}' || '[/]' || z_asgard.asgard_role_trans_acl(relowner::regrole))
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'Journal du mur_id_seq' ;
        
    r := r AND b ;
    
    ------ modification du lecteur (vers public) ------
    UPDATE z_asgard.gestion_schema_usr
        SET lecteur = 'public'
        WHERE nom_schema = 'c_Bibliothèque' ;
    
    SELECT array_to_string(nspacl, ',') ~ ('^(.*,)?=[UC]{2}' || '[/]' || z_asgard.asgard_role_trans_acl(nspowner::regrole))
        INTO STRICT b
        FROM pg_catalog.pg_namespace
        WHERE nspname = 'c_Bibliothèque' ;
        
    r := r AND b ;
    
    SELECT array_to_string(relacl, ',') ~ ('^(.*,)?=[rw]{2}' || '[/]' || z_asgard.asgard_role_trans_acl(relowner::regrole))
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'Journal du mur' ;
        
    r := r AND b ;
    
    SELECT array_to_string(relacl, ',') ~ ('^(.*,)?=[rU]{2}' || '[/]' || z_asgard.asgard_role_trans_acl(relowner::regrole))
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relname = 'Journal du mur_id_seq' ;
        
    r := r AND b ;
    
    DROP SCHEMA "c_Bibliothèque" CASCADE ;
    DELETE FROM z_asgard.gestion_schema_usr WHERE nom_schema = 'c_Bibliothèque' ;
    
    DROP ROLE "Admin EXT" ;
    
    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t028b() IS 'ASGARD recette. TEST : transmission des modifications manuelles (lecteur public).' ;


-- FUNCTION: z_asgard_recette.t029()

CREATE OR REPLACE FUNCTION z_asgard_recette.t029()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
   e_mssg text ;
   e_detl text ;
BEGIN

    CREATE SCHEMA c_bibliotheque ; 
    
    ------ producteur rôle de connexion (erreur) ------
    UPDATE z_asgard.gestion_schema_usr
        SET producteur = 'consult.defaut'
        WHERE nom_schema = 'c_bibliotheque' ;

    DROP SCHEMA c_bibliotheque ;
    DELETE FROM z_asgard.gestion_schema_usr WHERE nom_schema = 'c_bibliotheque' ;
        
    RETURN False ;
    
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                            e_detl = PG_EXCEPTION_DETAIL ;
                            
    RETURN e_mssg ~ 'TA3[.]' OR e_detl ~ 'TA3[.]' OR False ;

END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t029() IS 'ASGARD recette. TEST : interdiction producteur rôle de connexion.' ;

-- FUNCTION: z_asgard_recette.t029b()

CREATE OR REPLACE FUNCTION z_asgard_recette.t029b()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
   e_mssg text ;
   e_detl text ;
BEGIN

    CREATE ROLE "Jon Snow" LOGIN ;

    CREATE SCHEMA "c_Bibliothèque" ; 
    
    ------ producteur rôle de connexion (erreur) ------
    UPDATE z_asgard.gestion_schema_usr
        SET producteur = 'Jon Snow'
        WHERE nom_schema = 'c_Bibliothèque' ;

    DROP SCHEMA "c_Bibliothèque" ;
    DELETE FROM z_asgard.gestion_schema_usr WHERE nom_schema = 'c_Bibliothèque' ;
    
    DROP ROLE "Jon Snow" ;
    
    RETURN False ;
    
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                            e_detl = PG_EXCEPTION_DETAIL ;
                            
    RETURN e_mssg ~ 'TA3[.]' OR e_detl ~ 'TA3[.]' OR False ;

END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t029b() IS 'ASGARD recette. TEST : interdiction producteur rôle de connexion.' ;


-- FUNCTION: z_asgard_recette.t030()

CREATE OR REPLACE FUNCTION z_asgard_recette.t030()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
BEGIN

    CREATE SCHEMA c_bibliotheque ; 
    
    ------ schéma actif, modification du champ oid_schema ------
    UPDATE z_asgard.gestion_schema_etr
        SET oid_schema = 0
        WHERE nom_schema = 'c_bibliotheque' ;
        
    SELECT oid_schema = quote_ident(nom_schema)::regnamespace::oid
        INTO STRICT b
        FROM z_asgard.gestion_schema_etr
        WHERE nom_schema = 'c_bibliotheque' ;
         
    r := b ;
    
    ------ schéma actif, modification du champ oid_producteur ------
    UPDATE z_asgard.gestion_schema_etr
        SET oid_producteur = 0
        WHERE nom_schema = 'c_bibliotheque' ;
        
    SELECT oid_producteur = quote_ident(producteur)::regrole::oid
        INTO STRICT b
        FROM z_asgard.gestion_schema_etr
        WHERE nom_schema = 'c_bibliotheque' ;
         
    r := r AND b ;
    
    ------ schéma actif, modification du champ oid_editeur (NULL) ------
    UPDATE z_asgard.gestion_schema_etr
        SET oid_editeur = 0
        WHERE nom_schema = 'c_bibliotheque' ;
        
    SELECT oid_editeur IS NULL
        INTO STRICT b
        FROM z_asgard.gestion_schema_etr
        WHERE nom_schema = 'c_bibliotheque' ;
         
    r := r AND b ;
    
    ------ schéma actif, modification du champ oid_editeur (non NULL) ------
    UPDATE z_asgard.gestion_schema_usr
        SET editeur = 'g_admin_ext'
        WHERE nom_schema = 'c_bibliotheque' ;
        
    UPDATE z_asgard.gestion_schema_etr
        SET oid_editeur = 0
        WHERE nom_schema = 'c_bibliotheque' ;
        
    SELECT oid_editeur = quote_ident(editeur)::regrole::oid
        INTO STRICT b
        FROM z_asgard.gestion_schema_etr
        WHERE nom_schema = 'c_bibliotheque' ;
         
    r := r AND b ;
    
    ------ schéma actif, modification du champ oid_lecteur (NULL) ------
    UPDATE z_asgard.gestion_schema_etr
        SET oid_lecteur = 0
        WHERE nom_schema = 'c_bibliotheque' ;
        
    SELECT oid_lecteur IS NULL
        INTO STRICT b
        FROM z_asgard.gestion_schema_etr
        WHERE nom_schema = 'c_bibliotheque' ;
         
    r := r AND b ;
    
    ------ schéma actif, modification du champ oid_lecteur (non NULL) ------
    UPDATE z_asgard.gestion_schema_usr
        SET lecteur = 'g_consult'
        WHERE nom_schema = 'c_bibliotheque' ;
        
    UPDATE z_asgard.gestion_schema_etr
        SET oid_lecteur = 0
        WHERE nom_schema = 'c_bibliotheque' ;
        
    SELECT oid_lecteur = lecteur::regrole::oid
        INTO STRICT b
        FROM z_asgard.gestion_schema_etr
        WHERE nom_schema = 'c_bibliotheque' ;
         
    r := r AND b ;
    
    DROP SCHEMA c_bibliotheque ;
    
    ------ schéma inactif, modification du champ oid_schema ------
    UPDATE z_asgard.gestion_schema_etr
        SET oid_schema = 0
        WHERE nom_schema = 'c_bibliotheque' ;
        
    SELECT oid_schema IS NULL
        INTO STRICT b
        FROM z_asgard.gestion_schema_etr
        WHERE nom_schema = 'c_bibliotheque' ;
         
    r := r AND b ;
    
    ------ schéma actif, modification du champ oid_producteur ------
    UPDATE z_asgard.gestion_schema_etr
        SET oid_producteur = 0
        WHERE nom_schema = 'c_bibliotheque' ;
        
    SELECT oid_producteur IS NULL
        INTO STRICT b
        FROM z_asgard.gestion_schema_etr
        WHERE nom_schema = 'c_bibliotheque' ;
         
    r := r AND b ;
    
    ------ schéma actif, modification du champ oid_editeur ------
    UPDATE z_asgard.gestion_schema_etr
        SET oid_editeur = 0
        WHERE nom_schema = 'c_bibliotheque' ;
        
    SELECT oid_editeur IS NULL
        INTO STRICT b
        FROM z_asgard.gestion_schema_etr
        WHERE nom_schema = 'c_bibliotheque' ;
         
    r := r AND b ;
    
    ------ schéma actif, modification du champ oid_lecteur (NULL) ------
    UPDATE z_asgard.gestion_schema_etr
        SET oid_lecteur = 0
        WHERE nom_schema = 'c_bibliotheque' ;
        
    SELECT oid_lecteur IS NULL
        INTO STRICT b
        FROM z_asgard.gestion_schema_etr
        WHERE nom_schema = 'c_bibliotheque' ;
         
    r := r AND b ;
        
    DELETE FROM z_asgard.gestion_schema_usr WHERE nom_schema = 'c_bibliotheque' ;
        
    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t030() IS 'ASGARD recette. TEST : annulation de la modification manuelle des OID.' ;

-- FUNCTION: z_asgard_recette.t030b()

CREATE OR REPLACE FUNCTION z_asgard_recette.t030b()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
BEGIN

    CREATE ROLE "Consult" ;
    CREATE ROLE "Admin EXT" ;

    CREATE SCHEMA "c_Bibliothèque" ; 
    
    ------ schéma actif, modification du champ oid_schema ------
    UPDATE z_asgard.gestion_schema_etr
        SET oid_schema = 0
        WHERE nom_schema = 'c_Bibliothèque' ;
        
    SELECT oid_schema = quote_ident(nom_schema)::regnamespace::oid
        INTO STRICT b
        FROM z_asgard.gestion_schema_etr
        WHERE nom_schema = 'c_Bibliothèque' ;
         
    r := b ;
    
    ------ schéma actif, modification du champ oid_producteur ------
    UPDATE z_asgard.gestion_schema_etr
        SET oid_producteur = 0
        WHERE nom_schema = 'c_Bibliothèque' ;
        
    SELECT oid_producteur = quote_ident(producteur)::regrole::oid
        INTO STRICT b
        FROM z_asgard.gestion_schema_etr
        WHERE nom_schema = 'c_Bibliothèque' ;
         
    r := r AND b ;
    
    ------ schéma actif, modification du champ oid_editeur (NULL) ------
    UPDATE z_asgard.gestion_schema_etr
        SET oid_editeur = 0
        WHERE nom_schema = 'c_Bibliothèque' ;
        
    SELECT oid_editeur IS NULL
        INTO STRICT b
        FROM z_asgard.gestion_schema_etr
        WHERE nom_schema = 'c_Bibliothèque' ;
         
    r := r AND b ;
    
    ------ schéma actif, modification du champ oid_editeur (non NULL) ------
    UPDATE z_asgard.gestion_schema_usr
        SET editeur = 'Admin EXT'
        WHERE nom_schema = 'c_Bibliothèque' ;
        
    UPDATE z_asgard.gestion_schema_etr
        SET oid_editeur = 0
        WHERE nom_schema = 'c_Bibliothèque' ;
        
    SELECT oid_editeur = quote_ident(editeur)::regrole::oid
        INTO STRICT b
        FROM z_asgard.gestion_schema_etr
        WHERE nom_schema = 'c_Bibliothèque' ;
         
    r := r AND b ;
    
    ------ schéma actif, modification du champ oid_lecteur (NULL) ------
    UPDATE z_asgard.gestion_schema_etr
        SET oid_lecteur = 0
        WHERE nom_schema = 'c_Bibliothèque' ;
        
    SELECT oid_lecteur IS NULL
        INTO STRICT b
        FROM z_asgard.gestion_schema_etr
        WHERE nom_schema = 'c_Bibliothèque' ;
         
    r := r AND b ;
    
    ------ schéma actif, modification du champ oid_lecteur (non NULL) ------
    UPDATE z_asgard.gestion_schema_usr
        SET lecteur = 'Consult'
        WHERE nom_schema = 'c_Bibliothèque' ;
        
    UPDATE z_asgard.gestion_schema_etr
        SET oid_lecteur = 0
        WHERE nom_schema = 'c_Bibliothèque' ;
        
    SELECT oid_lecteur = quote_ident(lecteur)::regrole::oid
        INTO STRICT b
        FROM z_asgard.gestion_schema_etr
        WHERE nom_schema = 'c_Bibliothèque' ;
         
    r := r AND b ;
    
    DROP SCHEMA "c_Bibliothèque" ;
    
    ------ schéma inactif, modification du champ oid_schema ------
    UPDATE z_asgard.gestion_schema_etr
        SET oid_schema = 0
        WHERE nom_schema = 'c_Bibliothèque' ;
        
    SELECT oid_schema IS NULL
        INTO STRICT b
        FROM z_asgard.gestion_schema_etr
        WHERE nom_schema = 'c_Bibliothèque' ;
         
    r := r AND b ;
    
    ------ schéma actif, modification du champ oid_producteur ------
    UPDATE z_asgard.gestion_schema_etr
        SET oid_producteur = 0
        WHERE nom_schema = 'c_Bibliothèque' ;
        
    SELECT oid_producteur IS NULL
        INTO STRICT b
        FROM z_asgard.gestion_schema_etr
        WHERE nom_schema = 'c_Bibliothèque' ;
         
    r := r AND b ;
    
    ------ schéma actif, modification du champ oid_editeur ------
    UPDATE z_asgard.gestion_schema_etr
        SET oid_editeur = 0
        WHERE nom_schema = 'c_Bibliothèque' ;
        
    SELECT oid_editeur IS NULL
        INTO STRICT b
        FROM z_asgard.gestion_schema_etr
        WHERE nom_schema = 'c_Bibliothèque' ;
         
    r := r AND b ;
    
    ------ schéma actif, modification du champ oid_lecteur (NULL) ------
    UPDATE z_asgard.gestion_schema_etr
        SET oid_lecteur = 0
        WHERE nom_schema = 'c_Bibliothèque' ;
        
    SELECT oid_lecteur IS NULL
        INTO STRICT b
        FROM z_asgard.gestion_schema_etr
        WHERE nom_schema = 'c_Bibliothèque' ;
         
    r := r AND b ;
        
    DELETE FROM z_asgard.gestion_schema_usr WHERE nom_schema = 'c_Bibliothèque' ;
    
    DROP ROLE "Consult" ;
    DROP ROLE "Admin EXT" ;
    
    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t030b() IS 'ASGARD recette. TEST : annulation de la modification manuelle des OID.' ;


-- FUNCTION: z_asgard_recette.t031()

CREATE OR REPLACE FUNCTION z_asgard_recette.t031()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
BEGIN

    CREATE SCHEMA c_bibliotheque ;
  
    ------ mise à la corbeille ------
    UPDATE z_asgard.gestion_schema_usr
        SET bloc = 'd'
        WHERE nom_schema = 'c_bibliotheque' ;
        
    SELECT count(*) = 1
        INTO STRICT b
        FROM z_asgard.gestion_schema_usr
        WHERE nom_schema = 'c_bibliotheque' AND bloc = 'd' ;
    
    r := b ;

    DROP SCHEMA c_bibliotheque ;
    DELETE FROM z_asgard.gestion_schema_usr WHERE nom_schema = 'c_bibliotheque' ;
        
    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t031() IS 'ASGARD recette. TEST : mise à la corbeille.' ;

-- FUNCTION: z_asgard_recette.t031b()

CREATE OR REPLACE FUNCTION z_asgard_recette.t031b()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
BEGIN

    CREATE SCHEMA "c_Bibliothèque" ;
  
    ------ mise à la corbeille ------
    UPDATE z_asgard.gestion_schema_usr
        SET bloc = 'd'
        WHERE nom_schema = 'c_Bibliothèque' ;
        
    SELECT count(*) = 1
        INTO STRICT b
        FROM z_asgard.gestion_schema_usr
        WHERE nom_schema = 'c_Bibliothèque' AND bloc = 'd' ;
    
    r := b ;

    DROP SCHEMA "c_Bibliothèque" ;
    DELETE FROM z_asgard.gestion_schema_usr WHERE nom_schema = 'c_Bibliothèque' ;
        
    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t031b() IS 'ASGARD recette. TEST : mise à la corbeille.' ;


-- FUNCTION: z_asgard_recette.t032()

CREATE OR REPLACE FUNCTION z_asgard_recette.t032()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
BEGIN

    CREATE SCHEMA c_bibliotheque ;
    
    UPDATE z_asgard.gestion_schema_usr
        SET bloc = 'd'
        WHERE nom_schema = 'c_bibliotheque' ;
  
    ------ sortie de la corbeille ------
    UPDATE z_asgard.gestion_schema_usr
        SET bloc = 'c'
        WHERE nom_schema = 'c_bibliotheque' ;
        
    SELECT bloc = 'c'
        INTO STRICT b
        FROM z_asgard.gestion_schema_usr
        WHERE nom_schema = 'c_bibliotheque' ;
    
    r := b ;

    DROP SCHEMA c_bibliotheque ;
    DELETE FROM z_asgard.gestion_schema_usr WHERE nom_schema = 'c_bibliotheque' ;
        
    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t032() IS 'ASGARD recette. TEST : sortie de la corbeille (restauration).' ;

-- FUNCTION: z_asgard_recette.t032b()

CREATE OR REPLACE FUNCTION z_asgard_recette.t032b()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
BEGIN

    CREATE SCHEMA "c_Bibliothèque" ;
    
    UPDATE z_asgard.gestion_schema_usr
        SET bloc = 'd'
        WHERE nom_schema = 'c_Bibliothèque' ;
  
    ------ sortie de la corbeille ------
    UPDATE z_asgard.gestion_schema_usr
        SET bloc = 'c'
        WHERE nom_schema = 'c_Bibliothèque' ;
        
    SELECT bloc = 'c'
        INTO STRICT b
        FROM z_asgard.gestion_schema_usr
        WHERE nom_schema = 'c_Bibliothèque' ;
    
    r := b ;

    DROP SCHEMA "c_Bibliothèque" ;
    DELETE FROM z_asgard.gestion_schema_usr WHERE nom_schema = 'c_Bibliothèque' ;
        
    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t032b() IS 'ASGARD recette. TEST : sortie de la corbeille (restauration).' ;


-- FUNCTION: z_asgard_recette.t033()

CREATE OR REPLACE FUNCTION z_asgard_recette.t033()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
BEGIN

    CREATE SCHEMA c_bibliotheque ;
    
    UPDATE z_asgard.gestion_schema_usr
        SET bloc = 'd'
        WHERE nom_schema = 'c_bibliotheque' ;
  
    ------ suppression d'un schéma de la corbeille ------
    UPDATE z_asgard.gestion_schema_usr
        SET creation = False
        WHERE nom_schema = 'c_bibliotheque' ;
        
    SELECT count(*) = 0
        INTO STRICT b
        FROM pg_catalog.pg_namespace
        WHERE nspname = 'c_bibliotheque' ;
    
    r := b ;

    DELETE FROM z_asgard.gestion_schema_usr WHERE nom_schema = 'c_bibliotheque' ;
        
    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t033() IS 'ASGARD recette. TEST : suppression d''un schéma mis à la corbeille.' ;

-- FUNCTION: z_asgard_recette.t033b()

CREATE OR REPLACE FUNCTION z_asgard_recette.t033b()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
BEGIN

    CREATE SCHEMA "c_Bibliothèque" ;
    
    UPDATE z_asgard.gestion_schema_usr
        SET bloc = 'd'
        WHERE nom_schema = 'c_Bibliothèque' ;
  
    ------ suppression d'un schéma de la corbeille ------
    UPDATE z_asgard.gestion_schema_usr
        SET creation = False
        WHERE nom_schema = 'c_Bibliothèque' ;
        
    SELECT count(*) = 0
        INTO STRICT b
        FROM pg_catalog.pg_namespace
        WHERE nspname = 'c_Bibliothèque' ;
    
    r := b ;

    DELETE FROM z_asgard.gestion_schema_usr WHERE nom_schema = 'c_Bibliothèque' ;
        
    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t033b() IS 'ASGARD recette. TEST : suppression d''un schéma mis à la corbeille.' ;


-- FUNCTION: z_asgard_recette.t034()

CREATE OR REPLACE FUNCTION z_asgard_recette.t034()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
   e_mssg text ;
   e_detl text ;
BEGIN

    CREATE SCHEMA c_bibliotheque AUTHORIZATION g_admin_ext ;
    EXECUTE 'GRANT CREATE ON DATABASE ' || current_database() || ' TO g_admin_ext' ;
  
    ------ avec g_admin_ext ------
    SET ROLE g_admin_ext ;
    
    BEGIN
        UPDATE z_asgard.gestion_schema_usr
            SET nomenclature = True
            WHERE nom_schema = 'c_bibliotheque' ;
            
        r := False ;
            
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                                 e_detl = PG_EXCEPTION_DETAIL ;
                            
        r := e_mssg ~ 'TB18[.]' OR e_detl ~ 'TB18[.]' OR False ;
    END ;
        
    ------ avec g_admin ------
    SET ROLE g_admin ;
    
    UPDATE z_asgard.gestion_schema_usr
        SET nomenclature = True
        WHERE nom_schema = 'c_bibliotheque' ;
        
    ------ avec g_admin_ext ------
    SET ROLE g_admin_ext ;
    
    BEGIN
        UPDATE z_asgard.gestion_schema_usr
            SET nomenclature = False
            WHERE nom_schema = 'c_bibliotheque' ;
            
        r := False ;
            
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                                 e_detl = PG_EXCEPTION_DETAIL ;
                            
        b := e_mssg ~ 'TB18[.]' OR e_detl ~ 'TB18[.]' OR False ;
        r := r AND b ;
    END ;
    
    BEGIN
        UPDATE z_asgard.gestion_schema_usr
            SET nom_schema = 'c_librairie'
            WHERE nom_schema = 'c_bibliotheque' ;
            
        r := False ;
            
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                                 e_detl = PG_EXCEPTION_DETAIL ;
                            
        b := e_mssg ~ 'TB18[.]' OR e_detl ~ 'TB18[.]' OR False ;
        r := r AND b ;
    END ;
    
    BEGIN
        UPDATE z_asgard.gestion_schema_usr
            SET niv1 = 'SERVICES'
            WHERE nom_schema = 'c_bibliotheque' ;
            
        r := False ;
            
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                                 e_detl = PG_EXCEPTION_DETAIL ;
                            
        b := e_mssg ~ 'TB18[.]' OR e_detl ~ 'TB18[.]' OR False ;
        r := r AND b ;
    END ;
            
    BEGIN
        UPDATE z_asgard.gestion_schema_usr
            SET niv2 = 'SERVICES'
            WHERE nom_schema = 'c_bibliotheque' ;
            
        r := False ;
            
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                                 e_detl = PG_EXCEPTION_DETAIL ;
                            
        b := e_mssg ~ 'TB18[.]' OR e_detl ~ 'TB18[.]' OR False ;
        r := r AND b ;
    END ;
    
    BEGIN
        UPDATE z_asgard.gestion_schema_usr
            SET niv1_abr = 'services'
            WHERE nom_schema = 'c_bibliotheque' ;
            
        r := False ;
            
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                                 e_detl = PG_EXCEPTION_DETAIL ;
                            
        b := e_mssg ~ 'TB18[.]' OR e_detl ~ 'TB18[.]' OR False ;
        r := r AND b ;
    END ;
            
    BEGIN
        UPDATE z_asgard.gestion_schema_usr
            SET niv2_abr = 'services'
            WHERE nom_schema = 'c_bibliotheque' ;
            
        r := False ;
            
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                                 e_detl = PG_EXCEPTION_DETAIL ;
                            
        b := e_mssg ~ 'TB18[.]' OR e_detl ~ 'TB18[.]' OR False ;
        r := r AND b ;
    END ;
    
    BEGIN
        UPDATE z_asgard.gestion_schema_usr
            SET bloc = 'd'
            WHERE nom_schema = 'c_bibliotheque' ;
            
        r := False ;
            
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                                 e_detl = PG_EXCEPTION_DETAIL ;
                            
        b := e_mssg ~ 'TB18[.]' OR e_detl ~ 'TB18[.]' OR False ;
        r := r AND b ;
    END ;
    
    
    ------ avec g_admin ------
    SET ROLE g_admin ;
    
    UPDATE z_asgard.gestion_schema_usr
        SET niv1 = 'SERVICES'
        WHERE nom_schema = 'c_bibliotheque' ;

    UPDATE z_asgard.gestion_schema_usr
        SET niv2 = 'SERVICES'
        WHERE nom_schema = 'c_bibliotheque' ;

    UPDATE z_asgard.gestion_schema_usr
        SET niv1_abr = 'services'
        WHERE nom_schema = 'c_bibliotheque' ;

    UPDATE z_asgard.gestion_schema_usr
        SET niv2_abr = 'services'
        WHERE nom_schema = 'c_bibliotheque' ;

    UPDATE z_asgard.gestion_schema_usr
        SET bloc = 'd'
        WHERE nom_schema = 'c_bibliotheque' ;
        
    UPDATE z_asgard.gestion_schema_usr
        SET nom_schema = 'c_librairie'
        WHERE nom_schema = 'c_bibliotheque' ;

    UPDATE z_asgard.gestion_schema_usr
        SET nomenclature = False
        WHERE nom_schema = 'c_librairie' ;

    DROP SCHEMA c_librairie ;
    DELETE FROM z_asgard.gestion_schema_usr WHERE nom_schema = 'c_librairie' ;
    EXECUTE 'REVOKE CREATE ON DATABASE ' || current_database() || ' FROM g_admin_ext' ;
    RESET ROLE ;
        
    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t034() IS 'ASGARD recette. TEST : verrouillage des champs de la nomenclature.' ;

-- FUNCTION: z_asgard_recette.t034b()

CREATE OR REPLACE FUNCTION z_asgard_recette.t034b()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
   e_mssg text ;
   e_detl text ;
BEGIN

    CREATE ROLE "Admin EXT" ;
    GRANT g_admin_ext TO "Admin EXT" ;

    CREATE SCHEMA "c_Bibliothèque" AUTHORIZATION "Admin EXT" ;
    EXECUTE 'GRANT CREATE ON DATABASE ' || current_database() || ' TO "Admin EXT"' ;
  
    ------ avec "Admin EXT" ------
    SET ROLE "Admin EXT" ;
    
    BEGIN
        UPDATE z_asgard.gestion_schema_usr
            SET nomenclature = True
            WHERE nom_schema = 'c_Bibliothèque' ;
            
        r := False ;
            
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                                 e_detl = PG_EXCEPTION_DETAIL ;
                            
        r := e_mssg ~ 'TB18[.]' OR e_detl ~ 'TB18[.]' OR False ;
    END ;
        
    ------ avec g_admin ------
    SET ROLE g_admin ;
    
    UPDATE z_asgard.gestion_schema_usr
        SET nomenclature = True
        WHERE nom_schema = 'c_Bibliothèque' ;
        
    ------ avec "Admin EXT" ------
    SET ROLE "Admin EXT" ;
    
    BEGIN
        UPDATE z_asgard.gestion_schema_usr
            SET nomenclature = False
            WHERE nom_schema = 'c_Bibliothèque' ;
            
        r := False ;
            
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                                 e_detl = PG_EXCEPTION_DETAIL ;
                            
        b := e_mssg ~ 'TB18[.]' OR e_detl ~ 'TB18[.]' OR False ;
        r := r AND b ;
    END ;
    
    BEGIN
        UPDATE z_asgard.gestion_schema_usr
            SET nom_schema = 'c_Librairie'
            WHERE nom_schema = 'c_Bibliothèque' ;
            
        r := False ;
            
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                                 e_detl = PG_EXCEPTION_DETAIL ;
                            
        b := e_mssg ~ 'TB18[.]' OR e_detl ~ 'TB18[.]' OR False ;
        r := r AND b ;
    END ;
    
    BEGIN
        UPDATE z_asgard.gestion_schema_usr
            SET niv1 = 'SERVICES'
            WHERE nom_schema = 'c_Bibliothèque' ;
            
        r := False ;
            
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                                 e_detl = PG_EXCEPTION_DETAIL ;
                            
        b := e_mssg ~ 'TB18[.]' OR e_detl ~ 'TB18[.]' OR False ;
        r := r AND b ;
    END ;
            
    BEGIN
        UPDATE z_asgard.gestion_schema_usr
            SET niv2 = 'SERVICES'
            WHERE nom_schema = 'c_Bibliothèque' ;
            
        r := False ;
            
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                                 e_detl = PG_EXCEPTION_DETAIL ;
                            
        b := e_mssg ~ 'TB18[.]' OR e_detl ~ 'TB18[.]' OR False ;
        r := r AND b ;
    END ;
    
    BEGIN
        UPDATE z_asgard.gestion_schema_usr
            SET niv1_abr = 'services'
            WHERE nom_schema = 'c_Bibliothèque' ;
            
        r := False ;
            
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                                 e_detl = PG_EXCEPTION_DETAIL ;
                            
        b := e_mssg ~ 'TB18[.]' OR e_detl ~ 'TB18[.]' OR False ;
        r := r AND b ;
    END ;
            
    BEGIN
        UPDATE z_asgard.gestion_schema_usr
            SET niv2_abr = 'services'
            WHERE nom_schema = 'c_Bibliothèque' ;
            
        r := False ;
            
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                                 e_detl = PG_EXCEPTION_DETAIL ;
                            
        b := e_mssg ~ 'TB18[.]' OR e_detl ~ 'TB18[.]' OR False ;
        r := r AND b ;
    END ;
    
    BEGIN
        UPDATE z_asgard.gestion_schema_usr
            SET bloc = 'd'
            WHERE nom_schema = 'c_Bibliothèque' ;
            
        r := False ;
            
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                                 e_detl = PG_EXCEPTION_DETAIL ;
                            
        b := e_mssg ~ 'TB18[.]' OR e_detl ~ 'TB18[.]' OR False ;
        r := r AND b ;
    END ;
    
    
    ------ avec g_admin ------
    SET ROLE g_admin ;
    
    UPDATE z_asgard.gestion_schema_usr
        SET niv1 = 'SERVICES'
        WHERE nom_schema = 'c_Bibliothèque' ;

    UPDATE z_asgard.gestion_schema_usr
        SET niv2 = 'SERVICES'
        WHERE nom_schema = 'c_Bibliothèque' ;

    UPDATE z_asgard.gestion_schema_usr
        SET niv1_abr = 'services'
        WHERE nom_schema = 'c_Bibliothèque' ;

    UPDATE z_asgard.gestion_schema_usr
        SET niv2_abr = 'services'
        WHERE nom_schema = 'c_Bibliothèque' ;

    UPDATE z_asgard.gestion_schema_usr
        SET bloc = 'd'
        WHERE nom_schema = 'c_Bibliothèque' ;
        
    UPDATE z_asgard.gestion_schema_usr
        SET nom_schema = 'c_Librairie'
        WHERE nom_schema = 'c_Bibliothèque' ;

    UPDATE z_asgard.gestion_schema_usr
        SET nomenclature = False
        WHERE nom_schema = 'c_Librairie' ;

    DROP SCHEMA "c_Librairie" ;
    DELETE FROM z_asgard.gestion_schema_usr WHERE nom_schema = 'c_Librairie' ;
    
    RESET ROLE ;
    EXECUTE 'REVOKE CREATE ON DATABASE ' || current_database() || ' FROM "Admin EXT"' ;
    DROP ROLE "Admin EXT" ;
        
    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t034b() IS 'ASGARD recette. TEST : verrouillage des champs de la nomenclature.' ;


-- FUNCTION: z_asgard_recette.t035()

CREATE OR REPLACE FUNCTION z_asgard_recette.t035()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
   e_mssg text ;
   e_detl text ;
BEGIN

    EXECUTE 'GRANT CREATE ON DATABASE ' || current_database() || ' TO g_admin_ext' ;
  
    ------ avec g_admin_ext ------
    SET ROLE g_admin_ext ;
    
    BEGIN
        INSERT INTO z_asgard.gestion_schema_usr (nom_schema, producteur, creation, nomenclature)
            VALUES ('c_bibliotheque', 'g_admin_ext', True, True) ;
            
        r := False ;
            
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                                 e_detl = PG_EXCEPTION_DETAIL ;
                            
        r := e_mssg ~ 'TB19[.]' OR e_detl ~ 'TB19[.]' OR False ;
    END ;
    
    ------ avec g_admin ------
    SET ROLE g_admin ;
    
    INSERT INTO z_asgard.gestion_schema_usr (nom_schema, producteur, creation, nomenclature)
            VALUES ('c_bibliotheque', 'g_admin_ext', True, True) ;
            

    UPDATE z_asgard.gestion_schema_usr
        SET nomenclature = False
        WHERE nom_schema = 'c_bibliotheque' ;
    DROP SCHEMA c_bibliotheque ;
    DELETE FROM z_asgard.gestion_schema_usr WHERE nom_schema = 'c_bibliotheque' ;
    EXECUTE 'REVOKE CREATE ON DATABASE ' || current_database() || ' FROM g_admin_ext' ;
    RESET ROLE ;
        
    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t035() IS 'ASGARD recette. TEST : création d''un schéma de la nomenclature.' ;

-- FUNCTION: z_asgard_recette.t035b()

CREATE OR REPLACE FUNCTION z_asgard_recette.t035b()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
   e_mssg text ;
   e_detl text ;
BEGIN

    CREATE ROLE "Admin EXT" ;
    GRANT g_admin_ext TO "Admin EXT" ;

    EXECUTE 'GRANT CREATE ON DATABASE ' || current_database() || ' TO "Admin EXT"' ;
  
    ------ avec "Admin EXT" ------
    SET ROLE "Admin EXT" ;
    
    BEGIN
        INSERT INTO z_asgard.gestion_schema_usr (nom_schema, producteur, creation, nomenclature)
            VALUES ('c_Bibliothèque', 'Admin EXT', True, True) ;
            
        r := False ;
            
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                                 e_detl = PG_EXCEPTION_DETAIL ;
                            
        r := e_mssg ~ 'TB19[.]' OR e_detl ~ 'TB19[.]' OR False ;
    END ;
    
    ------ avec g_admin ------
    SET ROLE g_admin ;
    
    INSERT INTO z_asgard.gestion_schema_usr (nom_schema, producteur, creation, nomenclature)
            VALUES ('c_Bibliothèque', 'Admin EXT', True, True) ;
            

    UPDATE z_asgard.gestion_schema_usr
        SET nomenclature = False
        WHERE nom_schema = 'c_Bibliothèque' ;
    DROP SCHEMA "c_Bibliothèque" ;
    DELETE FROM z_asgard.gestion_schema_usr WHERE nom_schema = 'c_Bibliothèque' ;
    
    RESET ROLE ;
    EXECUTE 'REVOKE CREATE ON DATABASE ' || current_database() || ' FROM "Admin EXT"' ;
    
    DROP ROLE "Admin EXT" ;
        
    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t035b() IS 'ASGARD recette. TEST : création d''un schéma de la nomenclature.' ;


-- FUNCTION: z_asgard_recette.t036()

CREATE OR REPLACE FUNCTION z_asgard_recette.t036()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
   e_mssg text ;
   e_detl text ;
BEGIN
    
    INSERT INTO z_asgard.gestion_schema_usr (nom_schema, producteur, creation, nomenclature)
            VALUES ('c_bibliotheque', 'g_admin_ext', True, True) ;
    DROP SCHEMA c_bibliotheque ;  

    ------ effacement de l'enregistrement ------
    DELETE FROM z_asgard.gestion_schema_usr WHERE nom_schema = 'c_bibliotheque' ;
    
    RETURN False ;
        
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                            e_detl = PG_EXCEPTION_DETAIL ;
                        
    r := e_mssg ~ 'TB3[.]' OR e_detl ~ 'TB3[.]' OR False ;
    UPDATE z_asgard.gestion_schema_usr
        SET nomenclature = False
        WHERE nom_schema = 'c_bibliotheque' ;
    DELETE FROM z_asgard.gestion_schema_usr WHERE nom_schema = 'c_bibliotheque' ;
    RETURN r ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t036() IS 'ASGARD recette. TEST : effacement d''un schéma de la nomenclature.' ;

-- FUNCTION: z_asgard_recette.t036b()

CREATE OR REPLACE FUNCTION z_asgard_recette.t036b()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
   e_mssg text ;
   e_detl text ;
BEGIN

    CREATE ROLE "Admin EXT" ;
    
    INSERT INTO z_asgard.gestion_schema_usr (nom_schema, producteur, creation, nomenclature)
            VALUES ('c_Bibliothèque', 'Admin EXT', True, True) ;
    DROP SCHEMA "c_Bibliothèque" ;  

    ------ effacement de l'enregistrement ------
    DELETE FROM z_asgard.gestion_schema_usr WHERE nom_schema = 'c_Bibliothèque' ;
    
    DROP ROLE "Admin EXT" ;
    
    RETURN False ;
        
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                            e_detl = PG_EXCEPTION_DETAIL ;
                        
    r := e_mssg ~ 'TB3[.]' OR e_detl ~ 'TB3[.]' OR False ;
    
    UPDATE z_asgard.gestion_schema_usr
        SET nomenclature = False
        WHERE nom_schema = 'c_Bibliothèque' ;
    DELETE FROM z_asgard.gestion_schema_usr WHERE nom_schema = 'c_Bibliothèque' ;
    
    RETURN r ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t036b() IS 'ASGARD recette. TEST : effacement d''un schéma de la nomenclature.' ;


-- FUNCTION: z_asgard_recette.t037()

CREATE OR REPLACE FUNCTION z_asgard_recette.t037()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
BEGIN
    
    CREATE SCHEMA c_bibliotheque ;
    
    ------ manipulation sur les blocs ------
    UPDATE z_asgard.gestion_schema_usr
        SET bloc = 'a'
        WHERE nom_schema = 'c_bibliotheque' ;
        
    SELECT count(*) = 1
        INTO STRICT b
        FROM z_asgard.gestion_schema_usr
        WHERE nom_schema = 'a_bibliotheque' AND bloc = 'a' ;
        
    r := b ;
    RAISE NOTICE '37-1 > %', r::text ;
        
    UPDATE z_asgard.gestion_schema_usr
        SET bloc = NULL
        WHERE nom_schema = 'a_bibliotheque' ;
        
    SELECT count(*) = 1
        INTO STRICT b
        FROM z_asgard.gestion_schema_usr
        WHERE nom_schema = 'bibliotheque' AND bloc IS NULL ;
        
    r := r AND b ;
    RAISE NOTICE '37-2 > %', r::text ;
        
    UPDATE z_asgard.gestion_schema_usr
        SET nom_schema = 'a_bibliotheque'
        WHERE nom_schema = 'bibliotheque' ;
        
    SELECT count(*) = 1
        INTO STRICT b
        FROM z_asgard.gestion_schema_usr
        WHERE nom_schema = 'a_bibliotheque' AND bloc = 'a' ;
        
    r := r AND b ;
    RAISE NOTICE '37-3 > %', r::text ;
        
    UPDATE z_asgard.gestion_schema_usr
        SET nom_schema = 'b_bibliotheque'
        WHERE nom_schema = 'a_bibliotheque' ;
        
    SELECT count(*) = 1
        INTO STRICT b
        FROM z_asgard.gestion_schema_usr
        WHERE nom_schema = 'b_bibliotheque' AND bloc = 'b' ;
        
    r := r AND b ;
    RAISE NOTICE '37-4 > %', r::text ;
        
    UPDATE z_asgard.gestion_schema_usr
        SET nom_schema = 'c_bibliotheque',
            bloc = 'a'
        WHERE nom_schema = 'b_bibliotheque' ;
        
    SELECT count(*) = 1
        INTO STRICT b
        FROM z_asgard.gestion_schema_usr
        WHERE nom_schema = 'a_bibliotheque' AND bloc = 'a' ;
        
    r := r AND b ;
    RAISE NOTICE '37-5 > %', r::text ;
    
    UPDATE z_asgard.gestion_schema_usr
        SET nom_schema = 'b_bibliotheque',
            bloc = NULL
        WHERE nom_schema = 'a_bibliotheque' ;
        
    SELECT count(*) = 1
        INTO STRICT b
        FROM z_asgard.gestion_schema_usr
        WHERE nom_schema = 'b_bibliotheque' AND bloc = 'b' ;
    
    r := r AND b ;
    RAISE NOTICE '37-6 > %', r::text ;
    
    UPDATE z_asgard.gestion_schema_usr
        SET nom_schema = 'bibliotheque',
            bloc = 'a'
        WHERE nom_schema = 'b_bibliotheque' ;
        
    SELECT count(*) = 1
        INTO STRICT b
        FROM z_asgard.gestion_schema_usr
        WHERE nom_schema = 'a_bibliotheque' AND bloc = 'a' ;
    
    r := r AND b ;
    RAISE NOTICE '37-7 > %', r::text ;
        
    UPDATE z_asgard.gestion_schema_usr
        SET nom_schema = 'bibliotheque'
        WHERE nom_schema = 'a_bibliotheque' ;
        
    SELECT count(*) = 1
        INTO STRICT b
        FROM z_asgard.gestion_schema_usr
        WHERE nom_schema = 'bibliotheque' AND bloc IS NULL ;
    
    r := r AND b ;
    RAISE NOTICE '37-8 > %', r::text ;

    DROP SCHEMA bibliotheque ;
    DELETE FROM z_asgard.gestion_schema_usr WHERE nom_schema = 'bibliotheque' ;

    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t037() IS 'ASGARD recette. TEST : cohérence bloc et nom schéma (hors corbeille).' ;

-- FUNCTION: z_asgard_recette.t037b()

CREATE OR REPLACE FUNCTION z_asgard_recette.t037b()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
BEGIN
    
    CREATE SCHEMA "c_Bibliothèque" ;
    
    ------ manipulation sur les blocs ------
    UPDATE z_asgard.gestion_schema_usr
        SET bloc = 'a'
        WHERE nom_schema = 'c_Bibliothèque' ;
        
    SELECT count(*) = 1
        INTO STRICT b
        FROM z_asgard.gestion_schema_usr
        WHERE nom_schema = 'a_Bibliothèque' AND bloc = 'a' ;
        
    r := b ;
    RAISE NOTICE '37b-1 > %', r::text ;
        
    UPDATE z_asgard.gestion_schema_usr
        SET bloc = NULL
        WHERE nom_schema = 'a_Bibliothèque' ;
        
    SELECT count(*) = 1
        INTO STRICT b
        FROM z_asgard.gestion_schema_usr
        WHERE nom_schema = 'Bibliothèque' AND bloc IS NULL ;
        
    r := r AND b ;
    RAISE NOTICE '37b-2 > %', r::text ;
        
    UPDATE z_asgard.gestion_schema_usr
        SET nom_schema = 'a_Bibliothèque'
        WHERE nom_schema = 'Bibliothèque' ;
        
    SELECT count(*) = 1
        INTO STRICT b
        FROM z_asgard.gestion_schema_usr
        WHERE nom_schema = 'a_Bibliothèque' AND bloc = 'a' ;
        
    r := r AND b ;
    RAISE NOTICE '37b-3 > %', r::text ;
        
    UPDATE z_asgard.gestion_schema_usr
        SET nom_schema = 'b_Bibliothèque'
        WHERE nom_schema = 'a_Bibliothèque' ;
        
    SELECT count(*) = 1
        INTO STRICT b
        FROM z_asgard.gestion_schema_usr
        WHERE nom_schema = 'b_Bibliothèque' AND bloc = 'b' ;
        
    r := r AND b ;
    RAISE NOTICE '37b-4 > %', r::text ;
        
    UPDATE z_asgard.gestion_schema_usr
        SET nom_schema = 'c_Bibliothèque',
            bloc = 'a'
        WHERE nom_schema = 'b_Bibliothèque' ;
        
    SELECT count(*) = 1
        INTO STRICT b
        FROM z_asgard.gestion_schema_usr
        WHERE nom_schema = 'a_Bibliothèque' AND bloc = 'a' ;
        
    r := r AND b ;
    RAISE NOTICE '37b-5 > %', r::text ;
    
    UPDATE z_asgard.gestion_schema_usr
        SET nom_schema = 'b_Bibliothèque',
            bloc = NULL
        WHERE nom_schema = 'a_Bibliothèque' ;
        
    SELECT count(*) = 1
        INTO STRICT b
        FROM z_asgard.gestion_schema_usr
        WHERE nom_schema = 'b_Bibliothèque' AND bloc = 'b' ;
    
    r := r AND b ;
    RAISE NOTICE '37b-6 > %', r::text ;
    
    UPDATE z_asgard.gestion_schema_usr
        SET nom_schema = 'Bibliothèque',
            bloc = 'a'
        WHERE nom_schema = 'b_Bibliothèque' ;
        
    SELECT count(*) = 1
        INTO STRICT b
        FROM z_asgard.gestion_schema_usr
        WHERE nom_schema = 'a_Bibliothèque' AND bloc = 'a' ;
    
    r := r AND b ;
    RAISE NOTICE '37b-7 > %', r::text ;
        
    UPDATE z_asgard.gestion_schema_usr
        SET nom_schema = 'Bibliothèque'
        WHERE nom_schema = 'a_Bibliothèque' ;
        
    SELECT count(*) = 1
        INTO STRICT b
        FROM z_asgard.gestion_schema_usr
        WHERE nom_schema = 'Bibliothèque' AND bloc IS NULL ;
    
    r := r AND b ;
    RAISE NOTICE '37b-8 > %', r::text ;

    DROP SCHEMA "Bibliothèque" ;
    DELETE FROM z_asgard.gestion_schema_usr WHERE nom_schema = 'Bibliothèque' ;

    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t037b() IS 'ASGARD recette. TEST : cohérence bloc et nom schéma (hors corbeille).' ;



-- FUNCTION: z_asgard_recette.t038()

CREATE OR REPLACE FUNCTION z_asgard_recette.t038()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
BEGIN
    
    ------ deux domaines ------
    PERFORM z_asgard_admin.asgard_import_nomenclature(ARRAY['eau', 'foret']) ;
        
    SELECT count(*) = 14
        INTO STRICT b
        FROM z_asgard.gestion_schema_usr
        WHERE NOT nom_schema = 'z_asgard_recette' ;
        
    r := b ;
    
    ------ toute la nomenclature ------
        
    PERFORM z_asgard_admin.asgard_import_nomenclature() ;
        
    SELECT count(*) = 107
        INTO STRICT b
        FROM z_asgard.gestion_schema_usr
        WHERE NOT nom_schema = 'z_asgard_recette' ;
        
    r := r AND b ;

    UPDATE z_asgard.gestion_schema_usr SET nomenclature = False ;
    DELETE FROM z_asgard.gestion_schema_usr WHERE NOT creation ;

    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t038() IS 'ASGARD recette. TEST : import de la nomenclature.' ;



-- FUNCTION: z_asgard_recette.t039()

CREATE OR REPLACE FUNCTION z_asgard_recette.t039()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
   s record ;
BEGIN
    
    ------ hors z_asgard_admin ------
    PERFORM z_asgard_admin.asgard_initialisation_gestion_schema(ARRAY['z_asgard_admin']) ;
        
    SELECT count(*) = 1
        INTO STRICT b
        FROM z_asgard.gestion_schema_usr
        WHERE NOT nom_schema = 'z_asgard_recette' ;
        
    r := b ;
    
    ------ le reste ------    
    PERFORM z_asgard_admin.asgard_initialisation_gestion_schema() ;
        
    SELECT count(*) = 2
        INTO STRICT b
        FROM z_asgard.gestion_schema_usr
        WHERE NOT nom_schema = 'z_asgard_recette' ;
        
    r := r AND b ;

    FOR s IN (SELECT * FROM z_asgard.gestion_schema_usr)
    LOOP
        PERFORM z_asgard_admin.asgard_sortie_gestion_schema(s.nom_schema) ;
    END LOOP ;
    DELETE FROM z_asgard.gestion_schema_usr ;

    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t039() IS 'ASGARD recette. TEST : initialisation de la table de gestion (référencement des schémas existants).' ;

-- FUNCTION: z_asgard_recette.t039b()

CREATE OR REPLACE FUNCTION z_asgard_recette.t039b()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
   s record ;
BEGIN

    CREATE SCHEMA "c_Bibliothèque" ;
    PERFORM z_asgard_admin.asgard_sortie_gestion_schema('c_Bibliothèque') ;
    
    ------ avec asgard_initialise_schema ------
    PERFORM z_asgard.asgard_initialise_schema('c_Bibliothèque') ;
        
    SELECT count(*) = 1
        INTO STRICT b
        FROM z_asgard.gestion_schema_usr
        WHERE nom_schema = 'c_Bibliothèque' ;
        
    r := b ;
    
    ------ avec asgard_initialisation_gestion_schema ------
    PERFORM z_asgard_admin.asgard_sortie_gestion_schema('c_Bibliothèque') ;
    PERFORM z_asgard_admin.asgard_initialisation_gestion_schema() ;
        
    SELECT count(*) = 1
        INTO STRICT b
        FROM z_asgard.gestion_schema_usr
        WHERE nom_schema = 'c_Bibliothèque' ;
        
    r := r AND b ;

    DROP SCHEMA "c_Bibliothèque" ;
    FOR s IN (SELECT * FROM z_asgard.gestion_schema_usr)
    LOOP
        PERFORM z_asgard_admin.asgard_sortie_gestion_schema(s.nom_schema) ;
    END LOOP ;
    DELETE FROM z_asgard.gestion_schema_usr ;

    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t039b() IS 'ASGARD recette. TEST : initialisation de la table de gestion (référencement des schémas existants).' ;


-- FUNCTION: z_asgard_recette.t040()

CREATE OR REPLACE FUNCTION z_asgard_recette.t040()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
BEGIN

    CREATE SCHEMA c_bibliotheque AUTHORIZATION g_admin ;
    
    ------ déréférencement ------
    PERFORM z_asgard_admin.asgard_sortie_gestion_schema('c_bibliotheque') ;
    
    ------ création de tables dont g_admin_ext est propriétaire ------
    -- avec une séquence serial
    CREATE TABLE c_bibliotheque.journal_du_mur (id serial PRIMARY KEY, jour date, entree text) ;
    ALTER TABLE c_bibliotheque.journal_du_mur OWNER TO g_admin_ext ;
    
    -- avec un champ identity
    -- (échouerait pour les versions antérieures à PG10)
    IF current_setting('server_version_num')::int >= 100000
    THEN
        EXECUTE 'CREATE TABLE c_bibliotheque.journal_du_mur_bis (id int PRIMARY KEY GENERATED ALWAYS AS IDENTITY, jour date, entree text)' ;
        ALTER TABLE c_bibliotheque.journal_du_mur_bis OWNER TO g_admin_ext ;
    END IF ;
    
    ------ référencement avec asgard_initialise_schema ------
    PERFORM z_asgard.asgard_initialise_schema('c_bibliotheque') ;
    
    SELECT relowner::regrole::text = 'g_admin'
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relnamespace = 'c_bibliotheque'::regnamespace::oid AND relname = 'journal_du_mur' ;
        
    r := b ;
    
    IF current_setting('server_version_num')::int >= 100000
    THEN
        SELECT relowner::regrole::text = 'g_admin'
            INTO STRICT b
            FROM pg_catalog.pg_class
            WHERE relnamespace = 'c_bibliotheque'::regnamespace::oid AND relname = 'journal_du_mur_bis' ;
            
        r := r AND b ;
    END IF ;
    
    SELECT relowner::regrole::text = 'g_admin'
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relnamespace = 'c_bibliotheque'::regnamespace::oid AND relname = 'journal_du_mur_id_seq' ;
        
    r := r AND b ;
    
    IF current_setting('server_version_num')::int >= 100000
    THEN
        SELECT relowner::regrole::text = 'g_admin'
            INTO STRICT b
            FROM pg_catalog.pg_class
            WHERE relnamespace = 'c_bibliotheque'::regnamespace::oid AND relname = 'journal_du_mur_bis_id_seq' ;
            
        r := r AND b ;
    END IF ;

    DROP SCHEMA c_bibliotheque CASCADE ;
    DELETE FROM z_asgard.gestion_schema_usr ;
        
    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t040() IS 'ASGARD recette. TEST : mise en cohérence des propriétaires lors du référencement avec asgard_initialise_schema.' ;

-- FUNCTION: z_asgard_recette.t040b()

CREATE OR REPLACE FUNCTION z_asgard_recette.t040b()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
BEGIN

    CREATE ROLE "Admin EXT" ;
    CREATE ROLE "Admin" ; 

    CREATE SCHEMA "c_Bibliothèque" AUTHORIZATION "Admin" ;
    
    ------ déréférencement ------
    PERFORM z_asgard_admin.asgard_sortie_gestion_schema('c_Bibliothèque') ;
    
    ------ création de tables dont "Admin EXT" est propriétaire ------
    -- avec une séquence serial
    CREATE TABLE "c_Bibliothèque"."Journal du mur" (id serial PRIMARY KEY, jour date, entree text) ;
    ALTER TABLE "c_Bibliothèque"."Journal du mur" OWNER TO "Admin EXT" ;
    
    -- avec un champ identity
    -- (échouerait pour les versions antérieures à PG10)
    IF current_setting('server_version_num')::int >= 100000
    THEN
        EXECUTE 'CREATE TABLE "c_Bibliothèque"."Journal du mur_bis" (id int PRIMARY KEY GENERATED ALWAYS AS IDENTITY, jour date, entree text)' ;
        ALTER TABLE "c_Bibliothèque"."Journal du mur_bis" OWNER TO "Admin EXT" ;
    END IF ;
    
    ------ référencement avec asgard_initialise_schema ------
    PERFORM z_asgard.asgard_initialise_schema('c_Bibliothèque') ;
    
    SELECT relowner::regrole::text = '"Admin"'
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relnamespace = '"c_Bibliothèque"'::regnamespace::oid AND relname = 'Journal du mur' ;
        
    r := b ;
    
    IF current_setting('server_version_num')::int >= 100000
    THEN
        SELECT relowner::regrole::text = '"Admin"'
            INTO STRICT b
            FROM pg_catalog.pg_class
            WHERE relnamespace = '"c_Bibliothèque"'::regnamespace::oid AND relname = 'Journal du mur_bis' ;
            
        r := r AND b ;
    END IF ;
    
    SELECT relowner::regrole::text = '"Admin"'
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relnamespace = '"c_Bibliothèque"'::regnamespace::oid AND relname = 'Journal du mur_id_seq' ;
        
    r := r AND b ;
    
    IF current_setting('server_version_num')::int >= 100000
    THEN
        SELECT relowner::regrole::text = '"Admin"'
            INTO STRICT b
            FROM pg_catalog.pg_class
            WHERE relnamespace = '"c_Bibliothèque"'::regnamespace::oid AND relname = 'Journal du mur_bis_id_seq' ;
            
        r := r AND b ;
    END IF ;

    DROP SCHEMA "c_Bibliothèque" CASCADE ;
    DELETE FROM z_asgard.gestion_schema_usr ;
    
    DROP ROLE "Admin EXT" ;
    DROP ROLE "Admin" ;
        
    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t040b() IS 'ASGARD recette. TEST : mise en cohérence des propriétaires lors du référencement avec asgard_initialise_schema.' ;


-- FUNCTION: z_asgard_recette.t041()

CREATE OR REPLACE FUNCTION z_asgard_recette.t041()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
   s record ;
BEGIN

    CREATE SCHEMA c_bibliotheque AUTHORIZATION g_admin ;
    
    ------ déréférencement ------
    PERFORM z_asgard_admin.asgard_sortie_gestion_schema('c_bibliotheque') ;
    
    ------ création de tables dont g_admin_ext est propriétaire ------
    -- avec une séquence serial
    CREATE TABLE c_bibliotheque.journal_du_mur (id serial PRIMARY KEY, jour date, entree text) ;
    ALTER TABLE c_bibliotheque.journal_du_mur OWNER TO g_admin_ext ;
    
    -- avec un champ identity
    -- (échouerait pour les versions antérieures à PG10)
    IF current_setting('server_version_num')::int >= 100000
    THEN
        EXECUTE 'CREATE TABLE c_bibliotheque.journal_du_mur_bis (id int PRIMARY KEY GENERATED ALWAYS AS IDENTITY, jour date, entree text)' ;
        ALTER TABLE c_bibliotheque.journal_du_mur_bis OWNER TO g_admin_ext ;
    END IF ;
    
    ------ référencement avec asgard_initialisation_gestion_schema ------
    PERFORM z_asgard_admin.asgard_initialisation_gestion_schema() ;
    
    SELECT relowner::regrole::text = 'g_admin'
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relnamespace = 'c_bibliotheque'::regnamespace::oid AND relname = 'journal_du_mur' ;
        
    r := b ;
    
    IF current_setting('server_version_num')::int >= 100000
    THEN
        SELECT relowner::regrole::text = 'g_admin'
            INTO STRICT b
            FROM pg_catalog.pg_class
            WHERE relnamespace = 'c_bibliotheque'::regnamespace::oid AND relname = 'journal_du_mur_bis' ;
            
        r := r AND b ;
    END IF ;
    
    SELECT relowner::regrole::text = 'g_admin'
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relnamespace = 'c_bibliotheque'::regnamespace::oid AND relname = 'journal_du_mur_id_seq' ;
        
    r := r AND b ;
    
    IF current_setting('server_version_num')::int >= 100000
    THEN
        SELECT relowner::regrole::text = 'g_admin'
            INTO STRICT b
            FROM pg_catalog.pg_class
            WHERE relnamespace = 'c_bibliotheque'::regnamespace::oid AND relname = 'journal_du_mur_bis_id_seq' ;
            
        r := r AND b ;
    END IF ;

    ------ remise à zéro ------
    DROP SCHEMA c_bibliotheque CASCADE ;
    DELETE FROM z_asgard.gestion_schema_usr WHERE nom_schema = 'c_bibliotheque' ;
    
    FOR s IN (SELECT * FROM z_asgard.gestion_schema_usr)
    LOOP
        PERFORM z_asgard_admin.asgard_sortie_gestion_schema(s.nom_schema) ;
    END LOOP ;
    DELETE FROM z_asgard.gestion_schema_usr ;
        
    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t041() IS 'ASGARD recette. TEST : mise en cohérence des propriétaires lors du référencement avec asgard_initialisation_gestion_schema.' ;

-- FUNCTION: z_asgard_recette.t041b()

CREATE OR REPLACE FUNCTION z_asgard_recette.t041b()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
   s record ;
BEGIN

    CREATE ROLE "Admin EXT" ;
    CREATE ROLE "Admin" ;

    CREATE SCHEMA "c_Bibliothèque" AUTHORIZATION "Admin" ;
    
    ------ déréférencement ------
    PERFORM z_asgard_admin.asgard_sortie_gestion_schema('c_Bibliothèque') ;
    
    ------ création de tables dont "Admin EXT" est propriétaire ------
    -- avec une séquence serial
    CREATE TABLE "c_Bibliothèque"."Journal du mur" (id serial PRIMARY KEY, jour date, entree text) ;
    ALTER TABLE "c_Bibliothèque"."Journal du mur" OWNER TO "Admin EXT" ;
    
    -- avec un champ identity
    -- (échouerait pour les versions antérieures à PG10)
    IF current_setting('server_version_num')::int >= 100000
    THEN
        EXECUTE 'CREATE TABLE "c_Bibliothèque"."Journal du mur_bis" (id int PRIMARY KEY GENERATED ALWAYS AS IDENTITY, jour date, entree text)' ;
        ALTER TABLE "c_Bibliothèque"."Journal du mur_bis" OWNER TO "Admin EXT" ;
    END IF ;
    
    ------ référencement avec asgard_initialisation_gestion_schema ------
    PERFORM z_asgard_admin.asgard_initialisation_gestion_schema() ;
    
    SELECT relowner::regrole::text = '"Admin"'
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relnamespace = '"c_Bibliothèque"'::regnamespace::oid AND relname = 'Journal du mur' ;
        
    r := b ;
    
    IF current_setting('server_version_num')::int >= 100000
    THEN
        SELECT relowner::regrole::text = '"Admin"'
            INTO STRICT b
            FROM pg_catalog.pg_class
            WHERE relnamespace = '"c_Bibliothèque"'::regnamespace::oid AND relname = 'Journal du mur_bis' ;
            
        r := r AND b ;
    END IF ;
    
    SELECT relowner::regrole::text = '"Admin"'
        INTO STRICT b
        FROM pg_catalog.pg_class
        WHERE relnamespace = '"c_Bibliothèque"'::regnamespace::oid AND relname = 'Journal du mur_id_seq' ;
        
    r := r AND b ;
    
    IF current_setting('server_version_num')::int >= 100000
    THEN
        SELECT relowner::regrole::text = '"Admin"'
            INTO STRICT b
            FROM pg_catalog.pg_class
            WHERE relnamespace = '"c_Bibliothèque"'::regnamespace::oid AND relname = 'Journal du mur_bis_id_seq' ;
            
        r := r AND b ;
    END IF ;

    ------ remise à zéro ------
    DROP SCHEMA "c_Bibliothèque" CASCADE ;
    DELETE FROM z_asgard.gestion_schema_usr WHERE nom_schema = 'c_Bibliothèque' ;
    
    FOR s IN (SELECT * FROM z_asgard.gestion_schema_usr)
    LOOP
        PERFORM z_asgard_admin.asgard_sortie_gestion_schema(s.nom_schema) ;
    END LOOP ;
    DELETE FROM z_asgard.gestion_schema_usr ;
    
    DROP ROLE "Admin EXT" ;
    DROP ROLE "Admin" ;
        
    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t041b() IS 'ASGARD recette. TEST : mise en cohérence des propriétaires lors du référencement avec asgard_initialisation_gestion_schema.' ;


-- FUNCTION: z_asgard_recette.t042()

CREATE OR REPLACE FUNCTION z_asgard_recette.t042()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   r boolean ;
BEGIN

    CREATE SCHEMA c_bibliotheque ;
    
    UPDATE z_asgard.gestion_schema_usr
        SET producteur = 'rec_nouveau_producteur',
            editeur = 'rec_nouvel_editeur',
            lecteur = 'rec_nouveau_lecteur'
        WHERE nom_schema = 'c_bibliotheque' ;
    
    SELECT array_to_string(nspacl, ',') ~ 'rec_nouvel_editeur'::regrole::text
            AND array_to_string(nspacl, ',') ~ 'rec_nouveau_lecteur'::regrole::text
            AND nspowner = 'rec_nouveau_producteur'::regrole::oid
        INTO STRICT r
        FROM pg_catalog.pg_namespace
        WHERE nspname = 'c_bibliotheque' ;
    
    DROP SCHEMA c_bibliotheque CASCADE ;
    DELETE FROM z_asgard.gestion_schema_usr WHERE nom_schema = 'c_bibliotheque' ;
    
    DROP ROLE rec_nouveau_producteur ;
    DROP ROLE rec_nouvel_editeur ;
    DROP ROLE rec_nouveau_lecteur ;
        
    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t042() IS 'ASGARD recette. TEST : création de nouveaux rôles via un UPDATE dans la table de gestion.' ;


-- FUNCTION: z_asgard_recette.t042b()

CREATE OR REPLACE FUNCTION z_asgard_recette.t042b()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   r boolean ;
BEGIN

    CREATE SCHEMA "c_Bibliothèque" ;
    
    UPDATE z_asgard.gestion_schema_usr
        SET producteur = 'RECNouveauProducteur',
            editeur = 'REC\Nouvel éditeur',
            lecteur = 'REC"Nouveau lecteur'
        WHERE nom_schema = 'c_Bibliothèque' ;
    
    SELECT array_to_string(nspacl, ',') ~ z_asgard.asgard_role_trans_acl('"REC\Nouvel éditeur"'::regrole)
            AND array_to_string(nspacl, ',') ~ z_asgard.asgard_role_trans_acl('"REC""Nouveau lecteur"'::regrole)
            AND nspowner = '"RECNouveauProducteur"'::regrole::oid
        INTO STRICT r
        FROM pg_catalog.pg_namespace
        WHERE nspname = 'c_Bibliothèque' ;
    
    DROP SCHEMA "c_Bibliothèque" CASCADE ;
    DELETE FROM z_asgard.gestion_schema_usr WHERE nom_schema = 'c_Bibliothèque' ;
    
    DROP ROLE "RECNouveauProducteur" ;
    DROP ROLE "REC\Nouvel éditeur" ;
    DROP ROLE "REC""Nouveau lecteur" ;
        
    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t042b() IS 'ASGARD recette. TEST : création de nouveaux rôles via un UPDATE dans la table de gestion.' ;


-- FUNCTION: z_asgard_recette.t043()

CREATE OR REPLACE FUNCTION z_asgard_recette.t043()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   r boolean ;
BEGIN
    
    INSERT INTO z_asgard.gestion_schema_usr (nom_schema, creation, producteur, editeur, lecteur) VALUES
        ('c_bibliotheque', True, 'rec_nouveau_producteur', 'rec_nouvel_editeur', 'rec_nouveau_lecteur') ;
    
    SELECT array_to_string(nspacl, ',') ~ 'rec_nouvel_editeur'::regrole::text
            AND array_to_string(nspacl, ',') ~ 'rec_nouveau_lecteur'::regrole::text
            AND nspowner = 'rec_nouveau_producteur'::regrole::oid
        INTO STRICT r
        FROM pg_catalog.pg_namespace
        WHERE nspname = 'c_bibliotheque' ;
    
    DROP SCHEMA c_bibliotheque CASCADE ;
    DELETE FROM z_asgard.gestion_schema_usr WHERE nom_schema = 'c_bibliotheque' ;
    
    DROP ROLE rec_nouveau_producteur ;
    DROP ROLE rec_nouvel_editeur ;
    DROP ROLE rec_nouveau_lecteur ;
        
    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t043() IS 'ASGARD recette. TEST : création de nouveaux rôles via un INSERT dans la table de gestion.' ;


-- FUNCTION: z_asgard_recette.t043b()

CREATE OR REPLACE FUNCTION z_asgard_recette.t043b()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   r boolean ;
BEGIN
    
    INSERT INTO z_asgard.gestion_schema_usr (nom_schema, creation, producteur, editeur, lecteur) VALUES
        ('c_Bibliothèque', True, 'RECNouveauProducteur', 'REC\Nouvel éditeur', 'REC"Nouveau lecteur') ;
    
    SELECT array_to_string(nspacl, ',') ~ z_asgard.asgard_role_trans_acl('"REC\Nouvel éditeur"'::regrole)
            AND array_to_string(nspacl, ',') ~ z_asgard.asgard_role_trans_acl('"REC""Nouveau lecteur"'::regrole)
            AND nspowner = '"RECNouveauProducteur"'::regrole::oid
        INTO STRICT r
        FROM pg_catalog.pg_namespace
        WHERE nspname = 'c_Bibliothèque' ;
    
    DROP SCHEMA "c_Bibliothèque" CASCADE ;
    DELETE FROM z_asgard.gestion_schema_usr WHERE nom_schema = 'c_Bibliothèque' ;
    
    DROP ROLE "RECNouveauProducteur" ;
    DROP ROLE "REC\Nouvel éditeur" ;
    DROP ROLE "REC""Nouveau lecteur" ;
        
    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t043b() IS 'ASGARD recette. TEST : création de nouveaux rôles via un INSERT dans la table de gestion.' ;



-- FUNCTION: z_asgard_recette.t044()

CREATE OR REPLACE FUNCTION z_asgard_recette.t044()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   r boolean ;
BEGIN
    
    INSERT INTO z_asgard.gestion_schema_usr (nom_schema, creation, producteur, editeur, lecteur) VALUES
        ('c_bibliotheque', False, 'rec_nouveau_producteur', 'rec_nouvel_editeur', 'rec_nouveau_lecteur') ;
        
    UPDATE z_asgard.gestion_schema_usr
        SET creation = True
        WHERE nom_schema = 'c_bibliotheque' ;
    
    SELECT array_to_string(nspacl, ',') ~ 'rec_nouvel_editeur'::regrole::text
            AND array_to_string(nspacl, ',') ~ 'rec_nouveau_lecteur'::regrole::text
            AND nspowner = 'rec_nouveau_producteur'::regrole::oid
        INTO STRICT r
        FROM pg_catalog.pg_namespace
        WHERE nspname = 'c_bibliotheque' ;
    
    DROP SCHEMA c_bibliotheque CASCADE ;
    DELETE FROM z_asgard.gestion_schema_usr WHERE nom_schema = 'c_bibliotheque' ;
    
    DROP ROLE rec_nouveau_producteur ;
    DROP ROLE rec_nouvel_editeur ;
    DROP ROLE rec_nouveau_lecteur ;
        
    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t044() IS 'ASGARD recette. TEST : création de nouveaux rôles par bascule de creation.' ;



-- FUNCTION: z_asgard_recette.t044b()

CREATE OR REPLACE FUNCTION z_asgard_recette.t044b()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   r boolean ;
BEGIN
    
    INSERT INTO z_asgard.gestion_schema_usr (nom_schema, creation, producteur, editeur, lecteur) VALUES
        ('c_Bibliothèque', False, 'RECNouveauProducteur', 'REC\Nouvel éditeur', 'REC"Nouveau lecteur') ;
        
    UPDATE z_asgard.gestion_schema_usr
        SET creation = True
        WHERE nom_schema = 'c_Bibliothèque' ;
    
    SELECT array_to_string(nspacl, ',') ~ z_asgard.asgard_role_trans_acl('"REC\Nouvel éditeur"'::regrole)
            AND array_to_string(nspacl, ',') ~ z_asgard.asgard_role_trans_acl('"REC""Nouveau lecteur"'::regrole)
            AND nspowner = '"RECNouveauProducteur"'::regrole::oid
        INTO STRICT r
        FROM pg_catalog.pg_namespace
        WHERE nspname = 'c_Bibliothèque' ;
    
    DROP SCHEMA "c_Bibliothèque" CASCADE ;
    DELETE FROM z_asgard.gestion_schema_usr WHERE nom_schema = 'c_Bibliothèque' ;
    
    DROP ROLE "RECNouveauProducteur" ;
    DROP ROLE "REC\Nouvel éditeur" ;
    DROP ROLE "REC""Nouveau lecteur" ;
        
    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t044b() IS 'ASGARD recette. TEST : création de nouveaux rôles par bascule de creation.' ;


-- FUNCTION: z_asgard_recette.t045()

CREATE OR REPLACE FUNCTION z_asgard_recette.t045()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
   e_mssg text ;
   e_detl text ;
BEGIN

    CREATE SCHEMA c_bibliotheque ; 
    
    SET ROLE g_admin ;
    
    ------ modification du champ nom_schema ------
    BEGIN
        UPDATE z_asgard.gestion_schema_usr
            SET nom_schema = 'c_librairie'
            WHERE nom_schema = 'c_bibliotheque' ;
            
        RETURN False ;
        
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                                e_detl = PG_EXCEPTION_DETAIL ;
                                
        r := (e_mssg ~ 'TB20[.]' OR e_detl ~ 'TB20[.]' OR False) ;
    END ;
    
    ------ modification du champ producteur ------
    BEGIN
        UPDATE z_asgard.gestion_schema_usr
            SET producteur = 'g_admin'
            WHERE nom_schema = 'c_bibliotheque' ;
            
        RETURN False ;
        
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                                e_detl = PG_EXCEPTION_DETAIL ;
                                
        r := r AND (e_mssg ~ 'TB20[.]' OR e_detl ~ 'TB20[.]' OR False) ;
    END ;
    
    ------ modification du champ éditeur ------
    BEGIN
        UPDATE z_asgard.gestion_schema_usr
            SET editeur = 'g_admin'
            WHERE nom_schema = 'c_bibliotheque' ;
            
        RETURN False ;
        
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                                e_detl = PG_EXCEPTION_DETAIL ;
                                
        r := r AND (e_mssg ~ 'TB20[.]' OR e_detl ~ 'TB20[.]' OR False) ;
    END ;
    
    ------ modification du champ lecteur ------
    BEGIN
        UPDATE z_asgard.gestion_schema_usr
            SET lecteur = 'g_admin'
            WHERE nom_schema = 'c_bibliotheque' ;
            
        RETURN False ;
        
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                                e_detl = PG_EXCEPTION_DETAIL ;
                                
        r := r AND (e_mssg ~ 'TB20[.]' OR e_detl ~ 'TB20[.]' OR False) ;
    END ;
    
    ------ mise à la corbeille ------
    UPDATE z_asgard.gestion_schema_usr
        SET bloc = 'd'
        WHERE nom_schema = 'c_bibliotheque' ;
    
    ------ suppression du schéma dans la corbeille ------
    BEGIN
        UPDATE z_asgard.gestion_schema_usr
            SET creation = False
            WHERE nom_schema = 'c_bibliotheque' ;
            
        RETURN False ;
        
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                                e_detl = PG_EXCEPTION_DETAIL ;
                                
        r := r AND (e_mssg ~ 'TB23[.]' OR e_detl ~ 'TB23[.]' OR False) ;
    END ;
    
    ------ restauration du schéma ------
    UPDATE z_asgard.gestion_schema_usr
        SET bloc = 'c'
        WHERE nom_schema = 'c_bibliotheque' ;
        
    ------ déréférencement du schéma ------
    PERFORM z_asgard_admin.asgard_sortie_gestion_schema('c_bibliotheque') ;
    
    ------ référencement du schéma (avec asgard_initialise_schema) ------
    BEGIN
        PERFORM z_asgard.asgard_initialise_schema('c_bibliotheque') ;
    
        RETURN False ;
    
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                                e_detl = PG_EXCEPTION_DETAIL ;
                                
        r := r AND (e_mssg ~ 'TB25[.]' OR e_detl ~ 'TB25[.]'
                   OR e_mssg ~ 'FIS3[.]' OR e_detl ~ 'FIS3[.]' OR False) ;
    END ;
    
    ------ référencement du schéma (par un INSERT) ------
    BEGIN
        INSERT INTO z_asgard.gestion_schema_usr (nom_schema, producteur, creation)
            VALUES ('c_bibliotheque', 'postgres', True) ;
    
        RETURN False ;
    
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                                e_detl = PG_EXCEPTION_DETAIL ;
                                
        r := r AND (e_mssg ~ 'TB25[.]' OR e_detl ~ 'TB25[.]' OR False) ;
    END ;
    
    ------ création d'un schéma par INSERT ------
    BEGIN
        INSERT INTO z_asgard.gestion_schema_usr (nom_schema, producteur, creation)
            VALUES ('c_librairie', 'postgres', True) ;
            
        DROP SCHEMA IF EXISTS c_librairie ;
    
        RETURN False ;
    
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                                e_detl = PG_EXCEPTION_DETAIL ;
                                
        r := r AND (e_mssg ~ 'TB22[.]' OR e_detl ~ 'TB22[.]' OR False) ;
    END ;
    
    ------ création d'un schéma par bascule de creation ------
    INSERT INTO z_asgard.gestion_schema_usr (nom_schema, producteur, creation)
        VALUES ('c_librairie', 'postgres', False) ;
    
    BEGIN
        UPDATE z_asgard.gestion_schema_usr
            SET creation = True
            WHERE nom_schema = 'c_librairie' ; 
            
        DROP SCHEMA IF EXISTS c_librairie ;
    
        RETURN False ;
    
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                                e_detl = PG_EXCEPTION_DETAIL ;
                                
        r := r AND (e_mssg ~ 'TB21[.]' OR e_detl ~ 'TB21[.]' OR False) ;
    END ;
    
    ------ attributation à postgres d'un schéma existant ------
    INSERT INTO z_asgard.gestion_schema_usr (nom_schema, producteur, creation)
        VALUES ('c_archives', 'g_admin', True) ;
    
    BEGIN
        UPDATE z_asgard.gestion_schema_usr
            SET producteur = 'postgres'
            WHERE nom_schema = 'c_archives' ;
    
        RETURN False ;
    
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                                e_detl = PG_EXCEPTION_DETAIL ;
                                
        r := r AND (e_mssg ~ 'TB24[.]' OR e_detl ~ 'TB24[.]' OR False) ;
    END ;

    RESET ROLE ;
    DROP SCHEMA c_bibliotheque ;
    DROP SCHEMA c_archives ;
    DELETE FROM z_asgard.gestion_schema_usr WHERE nom_schema IN ('c_bibliotheque', 'c_librairie', 'c_archives') ;
        
    RETURN coalesce(r, False) ;
    
EXCEPTION WHEN OTHERS THEN
    RETURN False ;

END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t045() IS 'ASGARD recette. TEST : tentative d''action par g_admin sur les objets d''un super-utilisateur.' ;


-- FUNCTION: z_asgard_recette.t045b()

CREATE OR REPLACE FUNCTION z_asgard_recette.t045b()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
   e_mssg text ;
   e_detl text ;
BEGIN

    CREATE SCHEMA "c_Bibliothèque" ; 
    
    SET ROLE g_admin ;
    
    ------ modification du champ nom_schema ------
    BEGIN
        UPDATE z_asgard.gestion_schema_usr
            SET nom_schema = 'c_Librairie & Co'
            WHERE nom_schema = 'c_Bibliothèque' ;
            
        RETURN False ;
        
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                                e_detl = PG_EXCEPTION_DETAIL ;
                                
        r := (e_mssg ~ 'TB20[.]' OR e_detl ~ 'TB20[.]' OR False) ;
    END ;
    
    ------ modification du champ producteur ------
    BEGIN
        UPDATE z_asgard.gestion_schema_usr
            SET producteur = 'g_admin'
            WHERE nom_schema = 'c_Bibliothèque' ;
            
        RETURN False ;
        
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                                e_detl = PG_EXCEPTION_DETAIL ;
                                
        r := r AND (e_mssg ~ 'TB20[.]' OR e_detl ~ 'TB20[.]' OR False) ;
    END ;
    
    ------ modification du champ éditeur ------
    BEGIN
        UPDATE z_asgard.gestion_schema_usr
            SET editeur = 'g_admin'
            WHERE nom_schema = 'c_Bibliothèque' ;
            
        RETURN False ;
        
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                                e_detl = PG_EXCEPTION_DETAIL ;
                                
        r := r AND (e_mssg ~ 'TB20[.]' OR e_detl ~ 'TB20[.]' OR False) ;
    END ;
    
    ------ modification du champ lecteur ------
    BEGIN
        UPDATE z_asgard.gestion_schema_usr
            SET lecteur = 'g_admin'
            WHERE nom_schema = 'c_Bibliothèque' ;
            
        RETURN False ;
        
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                                e_detl = PG_EXCEPTION_DETAIL ;
                                
        r := r AND (e_mssg ~ 'TB20[.]' OR e_detl ~ 'TB20[.]' OR False) ;
    END ;
    
    ------ mise à la corbeille ------
    UPDATE z_asgard.gestion_schema_usr
        SET bloc = 'd'
        WHERE nom_schema = 'c_Bibliothèque' ;
    
    ------ suppression du schéma dans la corbeille ------
    BEGIN
        UPDATE z_asgard.gestion_schema_usr
            SET creation = False
            WHERE nom_schema = 'c_Bibliothèque' ;
            
        RETURN False ;
        
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                                e_detl = PG_EXCEPTION_DETAIL ;
                                
        r := r AND (e_mssg ~ 'TB23[.]' OR e_detl ~ 'TB23[.]' OR False) ;
    END ;
    
    ------ restauration du schéma ------
    UPDATE z_asgard.gestion_schema_usr
        SET bloc = 'c'
        WHERE nom_schema = 'c_Bibliothèque' ;
        
    ------ déréférencement du schéma ------
    PERFORM z_asgard_admin.asgard_sortie_gestion_schema('c_Bibliothèque') ;
    
    ------ référencement du schéma (avec asgard_initialise_schema) ------
    BEGIN
        PERFORM z_asgard.asgard_initialise_schema('c_Bibliothèque') ;
    
        RETURN False ;
    
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                                e_detl = PG_EXCEPTION_DETAIL ;
                                
        r := r AND (e_mssg ~ 'TB25[.]' OR e_detl ~ 'TB25[.]'
                   OR e_mssg ~ 'FIS3[.]' OR e_detl ~ 'FIS3[.]' OR False) ;
    END ;
    
    ------ référencement du schéma (par un INSERT) ------
    BEGIN
        INSERT INTO z_asgard.gestion_schema_usr (nom_schema, producteur, creation)
            VALUES ('c_Bibliothèque', 'postgres', True) ;
    
        RETURN False ;
    
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                                e_detl = PG_EXCEPTION_DETAIL ;
                                
        r := r AND (e_mssg ~ 'TB25[.]' OR e_detl ~ 'TB25[.]' OR False) ;
    END ;
    
    ------ création d'un schéma par INSERT ------
    BEGIN
        INSERT INTO z_asgard.gestion_schema_usr (nom_schema, producteur, creation)
            VALUES ('c_Librairie & Co', 'postgres', True) ;
            
        DROP SCHEMA IF EXISTS "c_Librairie & Co" ;
    
        RETURN False ;
    
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                                e_detl = PG_EXCEPTION_DETAIL ;
                                
        r := r AND (e_mssg ~ 'TB22[.]' OR e_detl ~ 'TB22[.]' OR False) ;
    END ;
    
    ------ création d'un schéma par bascule de creation ------
    INSERT INTO z_asgard.gestion_schema_usr (nom_schema, producteur, creation)
        VALUES ('c_Librairie & Co', 'postgres', False) ;
    
    BEGIN
        UPDATE z_asgard.gestion_schema_usr
            SET creation = True
            WHERE nom_schema = 'c_Librairie & Co' ; 
            
        DROP SCHEMA IF EXISTS "c_Librairie & Co" ;
    
        RETURN False ;
    
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                                e_detl = PG_EXCEPTION_DETAIL ;
                                
        r := r AND (e_mssg ~ 'TB21[.]' OR e_detl ~ 'TB21[.]' OR False) ;
    END ;
    
    ------ attributation à postgres d'un schéma existant ------
    INSERT INTO z_asgard.gestion_schema_usr (nom_schema, producteur, creation)
        VALUES ('c_*Archives*', 'g_admin', True) ;
    
    BEGIN
        UPDATE z_asgard.gestion_schema_usr
            SET producteur = 'postgres'
            WHERE nom_schema = 'c_*Archives*' ;
    
        RETURN False ;
    
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                                e_detl = PG_EXCEPTION_DETAIL ;
                                
        r := r AND (e_mssg ~ 'TB24[.]' OR e_detl ~ 'TB24[.]' OR False) ;
    END ;

    RESET ROLE ;
    DROP SCHEMA "c_Bibliothèque" ;
    DROP SCHEMA "c_*Archives*" ;
    DELETE FROM z_asgard.gestion_schema_usr WHERE nom_schema IN ('c_Bibliothèque', 'c_Librairie & Co', 'c_*Archives*') ;
        
    RETURN coalesce(r, False) ;
    
EXCEPTION WHEN OTHERS THEN
    RETURN False ;

END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t045b() IS 'ASGARD recette. TEST : tentative d''action par g_admin sur les objets d''un super-utilisateur.' ;


-- FUNCTION: z_asgard_recette.t046()

CREATE OR REPLACE FUNCTION z_asgard_recette.t046()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
   e_mssg text ;
   e_detl text ;
BEGIN

    CREATE SCHEMA c_bibliotheque ;
    CREATE SCHEMA c_librairie ;
    CREATE ROLE g_asgard_rec1 ;
    CREATE ROLE g_asgard_rec2 ;
    GRANT g_asgard_rec1 TO g_admin ;
    
    PERFORM z_asgard_admin.asgard_sortie_gestion_schema('c_librairie') ;
    
    ALTER DEFAULT PRIVILEGES IN SCHEMA c_bibliotheque GRANT ALL ON FUNCTIONS TO g_asgard_rec1 ;
    ALTER DEFAULT PRIVILEGES FOR ROLE g_admin IN SCHEMA c_bibliotheque GRANT ALL ON TABLES TO g_asgard_rec1 ;
    ALTER DEFAULT PRIVILEGES FOR ROLE g_admin_ext IN SCHEMA c_bibliotheque GRANT ALL ON SEQUENCES TO g_asgard_rec1 ;
    ALTER DEFAULT PRIVILEGES FOR ROLE g_admin IN SCHEMA c_librairie GRANT ALL ON TABLES TO g_asgard_rec1 ;
    ALTER DEFAULT PRIVILEGES GRANT ALL ON TYPES TO g_asgard_rec1 ;
    IF current_setting('server_version_num')::int >= 100000
    THEN
        EXECUTE 'ALTER DEFAULT PRIVILEGES FOR ROLE g_admin GRANT ALL ON SCHEMAS TO g_asgard_rec1' ;
    END IF ;
    
    ------ g_admin ------
    -- doit retourner une erreur puisque certains privilèges ont été conférés par postgres
    SET ROLE g_admin ;
    
    BEGIN
    
        PERFORM z_asgard_admin.asgard_reaffecte_role('g_asgard_rec1', NULL, True, True, True) ;
        RETURN False ;
    
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                                e_detl = PG_EXCEPTION_DETAIL ;
                                
        r := (e_mssg ~ 'FRR3[.]' OR e_detl ~ 'FRR3[.]' OR False) ;
        RAISE NOTICE '46-1 > %', r::text ;
    END ;
    
    RESET ROLE ;

    ------ transfert à g_asgard_rec2 (schémas référencés) ------
    SELECT z_asgard_admin.asgard_reaffecte_role('g_asgard_rec1', 'g_asgard_rec2', False, True, True) = ARRAY[current_database()::text]
        INTO STRICT b ;
        
    r := r AND b ;
    RAISE NOTICE '46-2 > %', r::text ;
    
    SELECT
        count(*) = 0
        INTO STRICT b 
        FROM pg_default_acl
        WHERE array_to_string(defaclacl, ',') ~ z_asgard.asgard_role_trans_acl(quote_ident('g_asgard_rec1')::regrole)
            AND defaclnamespace = quote_ident('c_bibliotheque')::regnamespace::oid ;
        
    r := r AND b ;
    RAISE NOTICE '46-2b > %', r::text ;
    
    SELECT
        count(*) = 1
        INTO STRICT b 
        FROM pg_default_acl
        WHERE defaclnamespace = quote_ident('c_librairie')::regnamespace::oid
            AND defaclrole = quote_ident('g_admin')::regrole::oid
            AND defaclobjtype = 'r'
            AND array_to_string(defaclacl, ',') ~ ('^(.*[,])?' || z_asgard.asgard_role_trans_acl(quote_ident('g_asgard_rec1')::regrole)
                    || '[=][rwadDxt]{7}[/]') ;
    
    r := r AND b ;
    RAISE NOTICE '46-3 > %', r::text ;
    
    IF current_setting('server_version_num')::int >= 100000
    THEN
        SELECT
            count(*) = 1
            INTO STRICT b 
            FROM pg_default_acl
            WHERE defaclnamespace = 0
                AND defaclrole = quote_ident('g_admin')::regrole::oid
                AND defaclobjtype = 'n'
                AND array_to_string(defaclacl, ',') ~ ('^(.*[,])?' || z_asgard.asgard_role_trans_acl(quote_ident('g_asgard_rec1')::regrole)
                        || '[=][UC]{2}[/]') ;
        
        r := r AND b ;
        RAISE NOTICE '46-4 > %', r::text ;
    END IF ;
    
    SELECT
        count(*) = 1
        INTO STRICT b 
        FROM pg_default_acl
        WHERE defaclnamespace = 0
            AND defaclrole = quote_ident(current_user)::regrole::oid
            AND defaclobjtype = 'T'
            AND array_to_string(defaclacl, ',') ~ ('^(.*[,])?' || z_asgard.asgard_role_trans_acl(quote_ident('g_asgard_rec1')::regrole)
                    || '[=]U[/]') ;
    
    r := r AND b ;
    RAISE NOTICE '46-5 > %', r::text ;
    
    SELECT
        count(*) = 1
        INTO STRICT b 
        FROM pg_default_acl
        WHERE defaclnamespace = quote_ident('c_bibliotheque')::regnamespace::oid
            AND defaclrole = quote_ident('g_admin')::regrole::oid
            AND defaclobjtype = 'r'
            AND array_to_string(defaclacl, ',') ~ ('^(.*[,])?' || z_asgard.asgard_role_trans_acl(quote_ident('g_asgard_rec2')::regrole)
                    || '[=][rwadDxt]{7}[/]') ;
    
    r := r AND b ;
    RAISE NOTICE '46-6 > %', r::text ;
    
    SELECT
        count(*) = 1
        INTO STRICT b 
        FROM pg_default_acl
        WHERE defaclnamespace = quote_ident('c_bibliotheque')::regnamespace::oid
            AND defaclrole = quote_ident('g_admin_ext')::regrole::oid
            AND defaclobjtype = 'S'
            AND array_to_string(defaclacl, ',') ~ ('^(.*[,])?' || z_asgard.asgard_role_trans_acl(quote_ident('g_asgard_rec2')::regrole)
                    || '[=][rwU]{3}[/]') ;
                    
    r := r AND b ;
    RAISE NOTICE '46-7 > %', r::text ;
    
    SELECT
        count(*) = 1
        INTO STRICT b 
        FROM pg_default_acl
        WHERE defaclnamespace = quote_ident('c_bibliotheque')::regnamespace::oid
            AND defaclrole = quote_ident(current_user)::regrole::oid
            AND defaclobjtype = 'f'
            AND array_to_string(defaclacl, ',') ~ ('^(.*[,])?' || z_asgard.asgard_role_trans_acl(quote_ident('g_asgard_rec2')::regrole)
                    || '[=]X[/]') ;
                    
    r := r AND b ;
    RAISE NOTICE '46-8 > %', r::text ;
    
    ------ transfert à g_asgard_rec2 (hors ASGARD) ------
    SELECT z_asgard_admin.asgard_reaffecte_role('g_asgard_rec1', 'g_asgard_rec2', True, True, True) IS NULL
        INTO STRICT b ;
        
    r := r AND b ;
    RAISE NOTICE '46-9 > %', r::text ;
    
    SELECT
        count(*) = 0
        INTO STRICT b 
        FROM pg_default_acl
        WHERE array_to_string(defaclacl, ',') ~ z_asgard.asgard_role_trans_acl(quote_ident('g_asgard_rec1')::regrole) ;
        
    r := r AND b ;
    RAISE NOTICE '46-9b > %', r::text ;
    
    SELECT
        count(*) = 1
        INTO STRICT b 
        FROM pg_default_acl
        WHERE defaclnamespace = quote_ident('c_librairie')::regnamespace::oid
            AND defaclrole = quote_ident('g_admin')::regrole::oid
            AND defaclobjtype = 'r'
            AND array_to_string(defaclacl, ',') ~ ('^(.*[,])?' || z_asgard.asgard_role_trans_acl(quote_ident('g_asgard_rec2')::regrole)
                    || '[=][rwadDxt]{7}[/]') ;
    
    r := r AND b ;
    RAISE NOTICE '46-10 > %', r::text ;
    
    IF current_setting('server_version_num')::int >= 100000
    THEN
        SELECT
            count(*) = 1
            INTO STRICT b 
            FROM pg_default_acl
            WHERE defaclnamespace = 0
                AND defaclrole = quote_ident('g_admin')::regrole::oid
                AND defaclobjtype = 'n'
                AND array_to_string(defaclacl, ',') ~ ('^(.*[,])?' || z_asgard.asgard_role_trans_acl(quote_ident('g_asgard_rec2')::regrole)
                        || '[=][UC]{2}[/]') ;
        
        r := r AND b ;
        RAISE NOTICE '46-11 > %', r::text ;
    END IF ;
    
    SELECT
        count(*) = 1
        INTO STRICT b 
        FROM pg_default_acl
        WHERE defaclnamespace = 0
            AND defaclrole = quote_ident(current_user)::regrole::oid
            AND defaclobjtype = 'T'
            AND array_to_string(defaclacl, ',') ~ ('^(.*[,])?' || z_asgard.asgard_role_trans_acl(quote_ident('g_asgard_rec2')::regrole)
                    || '[=]U[/]') ;
    
    r := r AND b ;
    RAISE NOTICE '46-12 > %', r::text ;
    
    ------ suppression (schémas référencés) ------
    SELECT z_asgard_admin.asgard_reaffecte_role('g_asgard_rec2', NULL, False, True, True)  = ARRAY[current_database()::text]
        INTO STRICT b ;
        
    r := r AND b ;
    RAISE NOTICE '46-13 > %', r::text ;
    
    SELECT
        count(*) = 0
        INTO STRICT b 
        FROM pg_default_acl
        WHERE array_to_string(defaclacl, ',') ~ z_asgard.asgard_role_trans_acl(quote_ident('g_asgard_rec2')::regrole)
            AND defaclnamespace = quote_ident('c_bibliotheque')::regnamespace::oid ;
    
    r := r AND b ;
    RAISE NOTICE '46-13b > %', r::text ;
    
    SELECT
        count(*) = 1
        INTO STRICT b 
        FROM pg_default_acl
        WHERE defaclnamespace = quote_ident('c_librairie')::regnamespace::oid
            AND defaclrole = quote_ident('g_admin')::regrole::oid
            AND defaclobjtype = 'r'
            AND array_to_string(defaclacl, ',') ~ ('^(.*[,])?' || z_asgard.asgard_role_trans_acl(quote_ident('g_asgard_rec2')::regrole)
                    || '[=][rwadDxt]{7}[/]') ;
    
    r := r AND b ;
    RAISE NOTICE '46-14 > %', r::text ;
    
    IF current_setting('server_version_num')::int >= 100000
    THEN
        SELECT
            count(*) = 1
            INTO STRICT b 
            FROM pg_default_acl
            WHERE defaclnamespace = 0
                AND defaclrole = quote_ident('g_admin')::regrole::oid
                AND defaclobjtype = 'n'
                AND array_to_string(defaclacl, ',') ~ ('^(.*[,])?' || z_asgard.asgard_role_trans_acl(quote_ident('g_asgard_rec2')::regrole)
                        || '[=][UC]{2}[/]') ;
        
        r := r AND b ;
        RAISE NOTICE '46-15 > %', r::text ;
    END IF ;
    
    SELECT
        count(*) = 1
        INTO STRICT b 
        FROM pg_default_acl
        WHERE defaclnamespace = 0
            AND defaclrole = quote_ident(current_user)::regrole::oid
            AND defaclobjtype = 'T'
            AND array_to_string(defaclacl, ',') ~ ('^(.*[,])?' || z_asgard.asgard_role_trans_acl(quote_ident('g_asgard_rec2')::regrole)
                    || '[=]U[/]') ;
    
    r := r AND b ;
    RAISE NOTICE '46-16 > %', r::text ;
    
    ------ suppression (tout) ------
    SELECT z_asgard_admin.asgard_reaffecte_role('g_asgard_rec2', NULL, True, True, True) IS NULL
        INTO STRICT b ;
        
    r := r AND b ;
    RAISE NOTICE '46-17 > %', r::text ;
    
    SELECT
        count(*) = 0
        INTO STRICT b 
        FROM pg_default_acl
        WHERE array_to_string(defaclacl, ',') ~ z_asgard.asgard_role_trans_acl(quote_ident('g_asgard_rec2')::regrole) ;
    
    r := r AND b ;
    RAISE NOTICE '46-18 > %', r::text ;
    
    DROP ROLE g_asgard_rec1 ;
    DROP ROLE g_asgard_rec2 ;
    
    DROP SCHEMA c_bibliotheque ;
    DROP SCHEMA c_librairie ;
    DELETE FROM z_asgard.gestion_schema_usr ;

    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t046() IS 'ASGARD recette. TEST : (asgard_reaffecte_role) réaffectation/suppression des privilèges par défaut d''un rôle.' ;


-- FUNCTION: z_asgard_recette.t046b()

CREATE OR REPLACE FUNCTION z_asgard_recette.t046b()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
   e_mssg text ;
   e_detl text ;
BEGIN

    CREATE SCHEMA "c_Bibliothèque" ;
    CREATE SCHEMA "c_Librairie" ;
    CREATE ROLE "g_ASGARD_REC1" ;
    CREATE ROLE "g_ASGARD *REC2" ;
    GRANT "g_ASGARD_REC1" TO g_admin ;
    
    PERFORM z_asgard_admin.asgard_sortie_gestion_schema('c_Librairie') ;
    
    ALTER DEFAULT PRIVILEGES IN SCHEMA "c_Bibliothèque" GRANT ALL ON FUNCTIONS TO "g_ASGARD_REC1" ;
    ALTER DEFAULT PRIVILEGES FOR ROLE g_admin IN SCHEMA "c_Bibliothèque" GRANT ALL ON TABLES TO "g_ASGARD_REC1" ;
    ALTER DEFAULT PRIVILEGES FOR ROLE g_admin_ext IN SCHEMA "c_Bibliothèque" GRANT ALL ON SEQUENCES TO "g_ASGARD_REC1" ;
    ALTER DEFAULT PRIVILEGES FOR ROLE g_admin IN SCHEMA "c_Librairie" GRANT ALL ON TABLES TO "g_ASGARD_REC1" ;
    ALTER DEFAULT PRIVILEGES GRANT ALL ON TYPES TO "g_ASGARD_REC1" ;
    IF current_setting('server_version_num')::int >= 100000
    THEN
        EXECUTE 'ALTER DEFAULT PRIVILEGES FOR ROLE g_admin GRANT ALL ON SCHEMAS TO "g_ASGARD_REC1"' ;
    END IF ;
    
    ------ g_admin ------
    -- doit retourner une erreur puisque certains privilèges ont été conférés par postgres
    SET ROLE g_admin ;
    
    BEGIN
    
        PERFORM z_asgard_admin.asgard_reaffecte_role('g_ASGARD_REC1', NULL, True, True, True) ;
        RETURN False ;
    
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                                e_detl = PG_EXCEPTION_DETAIL ;
                                
        r := (e_mssg ~ 'FRR3[.]' OR e_detl ~ 'FRR3[.]' OR False) ;
        RAISE NOTICE '46b-1 > %', r::text ;
    END ;
    
    RESET ROLE ;

    ------ transfert à "g_ASGARD *REC2" (schémas référencés) ------
    SELECT z_asgard_admin.asgard_reaffecte_role('g_ASGARD_REC1', 'g_ASGARD *REC2', False, True, True)  = ARRAY[current_database()::text]
        INTO STRICT b ;
        
    r := r AND b ;
    RAISE NOTICE '46b-2 > %', r::text ;
    
    SELECT
        count(*) = 0
        INTO STRICT b 
        FROM pg_default_acl
        WHERE array_to_string(defaclacl, ',') ~ z_asgard.asgard_role_trans_acl(quote_ident('g_ASGARD_REC1')::regrole)
            AND defaclnamespace = quote_ident('c_Bibliothèque')::regnamespace::oid ;
        
    r := r AND b ;
    RAISE NOTICE '46b-2b > %', r::text ;
    
    SELECT
        count(*) = 1
        INTO STRICT b 
        FROM pg_default_acl
        WHERE defaclnamespace = quote_ident('c_Librairie')::regnamespace::oid
            AND defaclrole = quote_ident('g_admin')::regrole::oid
            AND defaclobjtype = 'r'
            AND array_to_string(defaclacl, ',') ~ ('^(.*[,])?' || z_asgard.asgard_role_trans_acl(quote_ident('g_ASGARD_REC1')::regrole)
                    || '[=][rwadDxt]{7}[/]') ;
    
    r := r AND b ;
    RAISE NOTICE '46b-3 > %', r::text ;
    
    IF current_setting('server_version_num')::int >= 100000
    THEN
        SELECT
            count(*) = 1
            INTO STRICT b 
            FROM pg_default_acl
            WHERE defaclnamespace = 0
                AND defaclrole = quote_ident('g_admin')::regrole::oid
                AND defaclobjtype = 'n'
                AND array_to_string(defaclacl, ',') ~ ('^(.*[,])?' || z_asgard.asgard_role_trans_acl(quote_ident('g_ASGARD_REC1')::regrole)
                        || '[=][UC]{2}[/]') ;
        
        r := r AND b ;
        RAISE NOTICE '46b-4 > %', r::text ;
    END IF ;
    
    SELECT
        count(*) = 1
        INTO STRICT b 
        FROM pg_default_acl
        WHERE defaclnamespace = 0
            AND defaclrole = quote_ident(current_user)::regrole::oid
            AND defaclobjtype = 'T'
            AND array_to_string(defaclacl, ',') ~ ('^(.*[,])?' || z_asgard.asgard_role_trans_acl(quote_ident('g_ASGARD_REC1')::regrole)
                    || '[=]U[/]') ;
    
    r := r AND b ;
    RAISE NOTICE '46b-5 > %', r::text ;
    
    SELECT
        count(*) = 1
        INTO STRICT b 
        FROM pg_default_acl
        WHERE defaclnamespace = quote_ident('c_Bibliothèque')::regnamespace::oid
            AND defaclrole = quote_ident('g_admin')::regrole::oid
            AND defaclobjtype = 'r'
            AND array_to_string(defaclacl, ',') ~ ('^(.*[,])?' || z_asgard.asgard_role_trans_acl(quote_ident('g_ASGARD *REC2')::regrole)
                    || '[=][rwadDxt]{7}[/]') ;
    
    r := r AND b ;
    RAISE NOTICE '46b-6 > %', r::text ;
    
    SELECT
        count(*) = 1
        INTO STRICT b 
        FROM pg_default_acl
        WHERE defaclnamespace = quote_ident('c_Bibliothèque')::regnamespace::oid
            AND defaclrole = quote_ident('g_admin_ext')::regrole::oid
            AND defaclobjtype = 'S'
            AND array_to_string(defaclacl, ',') ~ ('^(.*[,])?' || z_asgard.asgard_role_trans_acl(quote_ident('g_ASGARD *REC2')::regrole)
                    || '[=][rwU]{3}[/]') ;
                    
    r := r AND b ;
    RAISE NOTICE '46b-7 > %', r::text ;
    
    SELECT
        count(*) = 1
        INTO STRICT b 
        FROM pg_default_acl
        WHERE defaclnamespace = quote_ident('c_Bibliothèque')::regnamespace::oid
            AND defaclrole = quote_ident(current_user)::regrole::oid
            AND defaclobjtype = 'f'
            AND array_to_string(defaclacl, ',') ~ ('^(.*[,])?' || z_asgard.asgard_role_trans_acl(quote_ident('g_ASGARD *REC2')::regrole)
                    || '[=]X[/]') ;
                    
    r := r AND b ;
    RAISE NOTICE '46b-8 > %', r::text ;
    
    ------ transfert à "g_ASGARD *REC2" (hors ASGARD) ------
    SELECT z_asgard_admin.asgard_reaffecte_role('g_ASGARD_REC1', 'g_ASGARD *REC2', True, True, True) IS NULL
        INTO STRICT b ;
        
    r := r AND b ;
    RAISE NOTICE '46b-9 > %', r::text ;
    
    SELECT
        count(*) = 0
        INTO STRICT b 
        FROM pg_default_acl
        WHERE array_to_string(defaclacl, ',') ~ z_asgard.asgard_role_trans_acl(quote_ident('g_ASGARD_REC1')::regrole) ;
        
    r := r AND b ;
    RAISE NOTICE '46b-9b > %', r::text ;
    
    SELECT
        count(*) = 1
        INTO STRICT b 
        FROM pg_default_acl
        WHERE defaclnamespace = quote_ident('c_Librairie')::regnamespace::oid
            AND defaclrole = quote_ident('g_admin')::regrole::oid
            AND defaclobjtype = 'r'
            AND array_to_string(defaclacl, ',') ~ ('^(.*[,])?' || z_asgard.asgard_role_trans_acl(quote_ident('g_ASGARD *REC2')::regrole)
                    || '[=][rwadDxt]{7}[/]') ;
    
    r := r AND b ;
    RAISE NOTICE '46b-10 > %', r::text ;
    
    IF current_setting('server_version_num')::int >= 100000
    THEN
        SELECT
            count(*) = 1
            INTO STRICT b 
            FROM pg_default_acl
            WHERE defaclnamespace = 0
                AND defaclrole = quote_ident('g_admin')::regrole::oid
                AND defaclobjtype = 'n'
                AND array_to_string(defaclacl, ',') ~ ('^(.*[,])?' || z_asgard.asgard_role_trans_acl(quote_ident('g_ASGARD *REC2')::regrole)
                        || '[=][UC]{2}[/]') ;
        
        r := r AND b ;
        RAISE NOTICE '46b-11 > %', r::text ;
    END IF ;
    
    SELECT
        count(*) = 1
        INTO STRICT b 
        FROM pg_default_acl
        WHERE defaclnamespace = 0
            AND defaclrole = quote_ident(current_user)::regrole::oid
            AND defaclobjtype = 'T'
            AND array_to_string(defaclacl, ',') ~ ('^(.*[,])?' || z_asgard.asgard_role_trans_acl(quote_ident('g_ASGARD *REC2')::regrole)
                    || '[=]U[/]') ;
    
    r := r AND b ;
    RAISE NOTICE '46b-12 > %', r::text ;
    
    ------ suppression (schémas référencés) ------
    SELECT z_asgard_admin.asgard_reaffecte_role('g_ASGARD *REC2', NULL, False, True, True) = ARRAY[current_database()::text]
        INTO STRICT b ;
        
    r := r AND b ;
    RAISE NOTICE '46b-13 > %', r::text ;
    
    SELECT
        count(*) = 0
        INTO STRICT b 
        FROM pg_default_acl
        WHERE array_to_string(defaclacl, ',') ~ z_asgard.asgard_role_trans_acl(quote_ident('g_ASGARD *REC2')::regrole)
            AND defaclnamespace = quote_ident('c_Bibliothèque')::regnamespace::oid ;
    
    r := r AND b ;
    RAISE NOTICE '46b-13b > %', r::text ;
    
    SELECT
        count(*) = 1
        INTO STRICT b 
        FROM pg_default_acl
        WHERE defaclnamespace = quote_ident('c_Librairie')::regnamespace::oid
            AND defaclrole = quote_ident('g_admin')::regrole::oid
            AND defaclobjtype = 'r'
            AND array_to_string(defaclacl, ',') ~ ('^(.*[,])?' || z_asgard.asgard_role_trans_acl(quote_ident('g_ASGARD *REC2')::regrole)
                    || '[=][rwadDxt]{7}[/]') ;
    
    r := r AND b ;
    RAISE NOTICE '46b-14 > %', r::text ;
    
    IF current_setting('server_version_num')::int >= 100000
    THEN
        SELECT
            count(*) = 1
            INTO STRICT b 
            FROM pg_default_acl
            WHERE defaclnamespace = 0
                AND defaclrole = quote_ident('g_admin')::regrole::oid
                AND defaclobjtype = 'n'
                AND array_to_string(defaclacl, ',') ~ ('^(.*[,])?' || z_asgard.asgard_role_trans_acl(quote_ident('g_ASGARD *REC2')::regrole)
                        || '[=][UC]{2}[/]') ;
        
        r := r AND b ;
        RAISE NOTICE '46b-15 > %', r::text ;
    END IF ;
    
    SELECT
        count(*) = 1
        INTO STRICT b 
        FROM pg_default_acl
        WHERE defaclnamespace = 0
            AND defaclrole = quote_ident(current_user)::regrole::oid
            AND defaclobjtype = 'T'
            AND array_to_string(defaclacl, ',') ~ ('^(.*[,])?' || z_asgard.asgard_role_trans_acl(quote_ident('g_ASGARD *REC2')::regrole)
                    || '[=]U[/]') ;
    
    r := r AND b ;
    RAISE NOTICE '46b-16 > %', r::text ;
    
    ------ suppression (tout) ------
    SELECT z_asgard_admin.asgard_reaffecte_role('g_ASGARD *REC2', NULL, True, True, True) IS NULL
        INTO STRICT b ;
        
    r := r AND b ;
    RAISE NOTICE '46b-17 > %', r::text ;
    
    SELECT
        count(*) = 0
        INTO STRICT b 
        FROM pg_default_acl
        WHERE array_to_string(defaclacl, ',') ~ z_asgard.asgard_role_trans_acl(quote_ident('g_ASGARD *REC2')::regrole) ;
    
    r := r AND b ;
    RAISE NOTICE '46b-18 > %', r::text ;
    
    DROP ROLE "g_ASGARD_REC1" ;
    DROP ROLE "g_ASGARD *REC2" ;
    
    DROP SCHEMA "c_Bibliothèque" ;
    DROP SCHEMA "c_Librairie" ;
    DELETE FROM z_asgard.gestion_schema_usr ;

    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t046b() IS 'ASGARD recette. TEST : (asgard_reaffecte_role) réaffectation/suppression des privilèges par défaut d''un rôle.' ;


-- FUNCTION: z_asgard_recette.t047()

CREATE OR REPLACE FUNCTION z_asgard_recette.t047()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
BEGIN
    
    ------ création ------
    -- #1
    CREATE SCHEMA d_bibliotheque ;
    
    SELECT count(*) = 1
        INTO STRICT b
        FROM z_asgard.gestion_schema_usr
        WHERE nom_schema = 'bibliotheque' AND bloc = 'd' ;
        
    r := b ;
    RAISE NOTICE '47-1 > %', r::text ;
    
    -- #2
    INSERT INTO z_asgard.gestion_schema_usr (nom_schema, producteur, creation)
        VALUES ('d_librairie', 'g_admin', True) ;
    
    SELECT count(*) = 1
        INTO STRICT b
        FROM z_asgard.gestion_schema_usr
        WHERE nom_schema = 'librairie' AND bloc = 'd' ;
        
    r := r AND b ;
    RAISE NOTICE '47-2 > %', r::text ;
    
    -- #3
    INSERT INTO z_asgard.gestion_schema_usr (nom_schema, bloc, producteur, creation)
        VALUES ('d_archives', 'x', 'g_admin', True) ;
    
    SELECT count(*) = 1
        INTO STRICT b
        FROM z_asgard.gestion_schema_usr
        WHERE nom_schema = 'x_archives' AND bloc = 'x' ;
        
    r := r AND b ;
    RAISE NOTICE '47-3 > %', r::text ;
    
    -- #4
    INSERT INTO z_asgard.gestion_schema_usr (nom_schema, bloc, producteur, creation)
        VALUES ('d_laboratoire', 'd', 'g_admin', True) ;
    
    SELECT count(*) = 1
        INTO STRICT b
        FROM z_asgard.gestion_schema_usr
        WHERE nom_schema = 'laboratoire' AND bloc = 'd' ;
        
    r := r AND b ;
    RAISE NOTICE '47-4 > %', r::text ;
        
    -- #5
    INSERT INTO z_asgard.gestion_schema_usr (nom_schema, bloc, producteur, creation)
        VALUES ('e_conservatoire', 'd', 'g_admin', True) ;
    
    SELECT count(*) = 1
        INTO STRICT b
        FROM z_asgard.gestion_schema_usr
        WHERE nom_schema = 'e_conservatoire' AND bloc = 'd' ;
        
    r := r AND b ;
    RAISE NOTICE '47-5 > %', r::text ;
    
    -- #6
    INSERT INTO z_asgard.gestion_schema_usr (nom_schema, bloc, producteur, creation)
        VALUES ('grenier', 'd', 'g_admin', True) ;
    
    SELECT count(*) = 1
        INTO STRICT b
        FROM z_asgard.gestion_schema_usr
        WHERE nom_schema = 'grenier' AND bloc = 'd' ;
        
    r := r AND b ;
    RAISE NOTICE '47-6 > %', r::text ;
    
    ------ modification ------
    -- #7
    ALTER SCHEMA bibliotheque
        RENAME TO d_bibliotheque ;
    
    SELECT count(*) = 1
        INTO STRICT b
        FROM z_asgard.gestion_schema_usr
        WHERE nom_schema = 'bibliotheque' AND bloc = 'd' ;
        
    r := r AND b ;
    RAISE NOTICE '47-7 > %', r::text ;
    
    -- #8
    ALTER SCHEMA bibliotheque
        RENAME TO c_bibliotheque ;
    
    SELECT count(*) = 1
        INTO STRICT b
        FROM z_asgard.gestion_schema_usr
        WHERE nom_schema = 'c_bibliotheque' AND bloc = 'd' ;
        
    r := r AND b ;
    RAISE NOTICE '47-8 > %', r::text ;

    -- #9
    ALTER SCHEMA x_archives
        RENAME TO d_archives ;
    
    SELECT count(*) = 1
        INTO STRICT b
        FROM z_asgard.gestion_schema_usr
        WHERE nom_schema = 'x_archives' AND bloc = 'd' ;
        
    r := r AND b ;
    RAISE NOTICE '47-9 > %', r::text ;
    
    -- #10
    CREATE SCHEMA galerie ;
    ALTER SCHEMA galerie
        RENAME TO d_galerie ;
        
    SELECT count(*) = 1
        INTO STRICT b
        FROM z_asgard.gestion_schema_usr
        WHERE nom_schema = 'galerie' AND bloc = 'd' ;
        
    r := r AND b ;
    RAISE NOTICE '47-10 > %', r::text ;

    -- #11
    UPDATE z_asgard.gestion_schema_usr
        SET bloc = NULL
        WHERE nom_schema = 'galerie' ;
        
    UPDATE z_asgard.gestion_schema_usr
        SET bloc = 'd',
            nom_schema = 'd_galerie'
        WHERE nom_schema = 'galerie' ;
        
    SELECT count(*) = 1
        INTO STRICT b
        FROM z_asgard.gestion_schema_usr
        WHERE nom_schema = 'galerie' AND bloc = 'd' ;
        
    r := r AND b ;
    RAISE NOTICE '47-11 > %', r::text ;    
        
    -- #12
    UPDATE z_asgard.gestion_schema_usr
        SET bloc = 'x'
        WHERE nom_schema = 'x_archives' ;
        
    UPDATE z_asgard.gestion_schema_usr
        SET bloc = 'd',
            nom_schema = 'd_archives'
        WHERE nom_schema = 'x_archives' ;
    
    SELECT count(*) = 1
        INTO STRICT b
        FROM z_asgard.gestion_schema_usr
        WHERE nom_schema = 'x_archives' AND bloc = 'd' ;
        
    r := r AND b ;
    RAISE NOTICE '47-12 > %', r::text ;
    
    -- #13
    UPDATE z_asgard.gestion_schema_usr
        SET bloc = 'c',
            nom_schema = 'd_archives'
        WHERE nom_schema = 'x_archives' ;
        
    SELECT count(*) = 1
        INTO STRICT b
        FROM z_asgard.gestion_schema_usr
        WHERE nom_schema = 'c_archives' AND bloc = 'c' ;
        
    r := r AND b ;
    RAISE NOTICE '47-13 > %', r::text ;

    DROP SCHEMA c_bibliotheque ;
    DROP SCHEMA librairie ;
    DROP SCHEMA c_archives ;
    DROP SCHEMA laboratoire ;
    DROP SCHEMA galerie ;
    DROP SCHEMA grenier ;
    DROP SCHEMA e_conservatoire ;    
    
    DELETE FROM z_asgard.gestion_schema_usr ;

    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t047() IS 'ASGARD recette. TEST : cohérence bloc et nom schéma (corbeille).' ;


-- FUNCTION: z_asgard_recette.t047b()

CREATE OR REPLACE FUNCTION z_asgard_recette.t047b()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
BEGIN
    
    ------ création ------
    -- #1
    CREATE SCHEMA "d_Bibliothèque" ;
    
    SELECT count(*) = 1
        INTO STRICT b
        FROM z_asgard.gestion_schema_usr
        WHERE nom_schema = 'Bibliothèque' AND bloc = 'd' ;
        
    r := b ;
    RAISE NOTICE '47b-1 > %', r::text ;
    
    -- #2
    INSERT INTO z_asgard.gestion_schema_usr (nom_schema, producteur, creation)
        VALUES ('d_*Librairie*', 'g_admin', True) ;
    
    SELECT count(*) = 1
        INTO STRICT b
        FROM z_asgard.gestion_schema_usr
        WHERE nom_schema = '*Librairie*' AND bloc = 'd' ;
        
    r := r AND b ;
    RAISE NOTICE '47b-2 > %', r::text ;
    
    -- #3
    INSERT INTO z_asgard.gestion_schema_usr (nom_schema, bloc, producteur, creation)
        VALUES ('d_*Les Archives', 'x', 'g_admin', True) ;
    
    SELECT count(*) = 1
        INTO STRICT b
        FROM z_asgard.gestion_schema_usr
        WHERE nom_schema = 'x_*Les Archives' AND bloc = 'x' ;
        
    r := r AND b ;
    RAISE NOTICE '47b-3 > %', r::text ;
    
    -- #4
    INSERT INTO z_asgard.gestion_schema_usr (nom_schema, bloc, producteur, creation)
        VALUES ('d_Laboratoire', 'd', 'g_admin', True) ;
    
    SELECT count(*) = 1
        INTO STRICT b
        FROM z_asgard.gestion_schema_usr
        WHERE nom_schema = 'Laboratoire' AND bloc = 'd' ;
        
    r := r AND b ;
    RAISE NOTICE '47b-4 > %', r::text ;
        
    -- #5
    INSERT INTO z_asgard.gestion_schema_usr (nom_schema, bloc, producteur, creation)
        VALUES ('e_Cons''ervatoire', 'd', 'g_admin', True) ;
    
    SELECT count(*) = 1
        INTO STRICT b
        FROM z_asgard.gestion_schema_usr
        WHERE nom_schema = 'e_Cons''ervatoire' AND bloc = 'd' ;
        
    r := r AND b ;
    RAISE NOTICE '47b-5 > %', r::text ;
    
    -- #6
    INSERT INTO z_asgard.gestion_schema_usr (nom_schema, bloc, producteur, creation)
        VALUES ('\grenier', 'd', 'g_admin', True) ;
    
    SELECT count(*) = 1
        INTO STRICT b
        FROM z_asgard.gestion_schema_usr
        WHERE nom_schema = '\grenier' AND bloc = 'd' ;
        
    r := r AND b ;
    RAISE NOTICE '47b-6 > %', r::text ;
    
    ------ modification ------
    -- #7
    ALTER SCHEMA "Bibliothèque"
        RENAME TO "d_Bibliothèque" ;
    
    SELECT count(*) = 1
        INTO STRICT b
        FROM z_asgard.gestion_schema_usr
        WHERE nom_schema = 'Bibliothèque' AND bloc = 'd' ;
        
    r := r AND b ;
    RAISE NOTICE '47b-7 > %', r::text ;
    
    -- #8
    ALTER SCHEMA "Bibliothèque"
        RENAME TO "c_Bibliothèque" ;
    
    SELECT count(*) = 1
        INTO STRICT b
        FROM z_asgard.gestion_schema_usr
        WHERE nom_schema = 'c_Bibliothèque' AND bloc = 'd' ;
        
    r := r AND b ;
    RAISE NOTICE '47b-8 > %', r::text ;

    -- #9
    ALTER SCHEMA "x_*Les Archives"
        RENAME TO "d_*Les Archives" ;
    
    SELECT count(*) = 1
        INTO STRICT b
        FROM z_asgard.gestion_schema_usr
        WHERE nom_schema = 'x_*Les Archives' AND bloc = 'd' ;
        
    r := r AND b ;
    RAISE NOTICE '47b-9 > %', r::text ;
    
    -- #10
    CREATE SCHEMA "GAL-E-RIE" ;
    ALTER SCHEMA "GAL-E-RIE"
        RENAME TO "d_GAL-E-RIE" ;
        
    SELECT count(*) = 1
        INTO STRICT b
        FROM z_asgard.gestion_schema_usr
        WHERE nom_schema = 'GAL-E-RIE' AND bloc = 'd' ;
        
    r := r AND b ;
    RAISE NOTICE '47b-10 > %', r::text ;

    -- #11
    UPDATE z_asgard.gestion_schema_usr
        SET bloc = NULL
        WHERE nom_schema = 'GAL-E-RIE' ;
        
    UPDATE z_asgard.gestion_schema_usr
        SET bloc = 'd',
            nom_schema = 'd_GAL-E-RIE'
        WHERE nom_schema = 'GAL-E-RIE' ;
        
    SELECT count(*) = 1
        INTO STRICT b
        FROM z_asgard.gestion_schema_usr
        WHERE nom_schema = 'GAL-E-RIE' AND bloc = 'd' ;
        
    r := r AND b ;
    RAISE NOTICE '47b-11 > %', r::text ;    
        
    -- #12
    UPDATE z_asgard.gestion_schema_usr
        SET bloc = 'x'
        WHERE nom_schema = 'x_*Les Archives' ;
        
    UPDATE z_asgard.gestion_schema_usr
        SET bloc = 'd',
            nom_schema = 'd_*Les Archives'
        WHERE nom_schema = 'x_*Les Archives' ;
    
    SELECT count(*) = 1
        INTO STRICT b
        FROM z_asgard.gestion_schema_usr
        WHERE nom_schema = 'x_*Les Archives' AND bloc = 'd' ;
        
    r := r AND b ;
    RAISE NOTICE '47b-12 > %', r::text ;
    
    -- #13
    UPDATE z_asgard.gestion_schema_usr
        SET bloc = 'c',
            nom_schema = 'd_*Les Archives'
        WHERE nom_schema = 'x_*Les Archives' ;
        
    SELECT count(*) = 1
        INTO STRICT b
        FROM z_asgard.gestion_schema_usr
        WHERE nom_schema = 'c_*Les Archives' AND bloc = 'c' ;
        
    r := r AND b ;
    RAISE NOTICE '47b-13 > %', r::text ;

    DROP SCHEMA "c_Bibliothèque" ;
    DROP SCHEMA "*Librairie*" ;
    DROP SCHEMA "c_*Les Archives" ;
    DROP SCHEMA "Laboratoire" ;
    DROP SCHEMA "GAL-E-RIE" ;
    DROP SCHEMA "\grenier" ;
    DROP SCHEMA "e_Cons'ervatoire" ;    
    
    DELETE FROM z_asgard.gestion_schema_usr ;

    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t047b() IS 'ASGARD recette. TEST : cohérence bloc et nom schéma (corbeille).' ;


-- FUNCTION: z_asgard_recette.t048()

CREATE OR REPLACE FUNCTION z_asgard_recette.t048()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
   e_mssg text ;
   e_detl text ;
   utilisateur text := current_user ;
BEGIN

    CREATE ROLE g_asgard_rec1 ;

    ------ réinitialisation des droits d'un schéma référencé ------
    CREATE SCHEMA c_bibliotheque AUTHORIZATION g_admin ;
    
    ALTER DEFAULT PRIVILEGES FOR ROLE g_admin IN SCHEMA c_bibliotheque GRANT ALL ON TABLES TO g_asgard_rec1 ;
    ALTER DEFAULT PRIVILEGES IN SCHEMA c_bibliotheque GRANT ALL ON SEQUENCES TO g_asgard_rec1 ;
    ALTER DEFAULT PRIVILEGES FOR ROLE g_admin IN SCHEMA c_bibliotheque GRANT ALL ON FUNCTIONS TO g_asgard_rec1 ;
    ALTER DEFAULT PRIVILEGES FOR ROLE g_admin IN SCHEMA c_bibliotheque GRANT ALL ON TYPES TO g_asgard_rec1 ;
    ALTER DEFAULT PRIVILEGES FOR ROLE g_admin IN SCHEMA c_bibliotheque GRANT SELECT ON TABLES TO public ;
    
    -- #1
    BEGIN
    SET ROLE g_admin ;
    
    PERFORM z_asgard.asgard_initialise_schema('c_bibliotheque') ;
    
    EXECUTE 'SET ROLE ' || utilisateur ;
    RETURN False ;
    
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                                e_detl = PG_EXCEPTION_DETAIL ;
                                
        r := (e_mssg ~ 'FIS6[.]' OR e_detl ~ 'FIS6[.]' OR False) ;
        RAISE NOTICE '48-1 > %', r::text ;
    END ;
    
    -- #2
    PERFORM z_asgard.asgard_initialise_schema('c_bibliotheque') ;
    
    SELECT
        count(*) = 0
        INTO STRICT b
        FROM pg_default_acl
        WHERE defaclnamespace = quote_ident('c_bibliotheque')::regnamespace::oid ;
    
    r := r AND b ;
    RAISE NOTICE '48-2 > %', r::text ;   

    ------ initialisation lors du référencement ------
    CREATE SCHEMA c_librairie ;
    PERFORM z_asgard_admin.asgard_sortie_gestion_schema('c_librairie') ;
    
    SET ROLE g_admin ;
    ALTER DEFAULT PRIVILEGES IN SCHEMA c_bibliotheque GRANT ALL ON TABLES TO g_asgard_rec1 ;
    
    -- #3
    PERFORM z_asgard.asgard_initialise_schema('c_bibliotheque') ;
    
    SELECT
        count(*) = 0
        INTO STRICT b 
        FROM pg_default_acl
        WHERE defaclnamespace = quote_ident('c_bibliotheque')::regnamespace::oid ;
        
    r := r AND b ;
    RAISE NOTICE '48-3 > %', r::text ; 
    
    EXECUTE 'SET ROLE ' || utilisateur ;
    
    DROP SCHEMA c_bibliotheque ;
    DROP SCHEMA c_librairie ;
    DROP ROLE g_asgard_rec1 ;
    DELETE FROM z_asgard.gestion_schema_usr ;    

    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t048() IS 'ASGARD recette. TEST : (asgard_initialise_schema) suppression des privilèges par défaut.' ;


-- FUNCTION: z_asgard_recette.t048b()

CREATE OR REPLACE FUNCTION z_asgard_recette.t048b()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
   e_mssg text ;
   e_detl text ;
   utilisateur text := current_user ;
BEGIN

    CREATE ROLE "g_ASGARD rec*1" ;

    ------ réinitialisation des droits d'un schéma référencé ------
    CREATE SCHEMA "c_Bibliothèque" AUTHORIZATION g_admin ;
    
    ALTER DEFAULT PRIVILEGES FOR ROLE g_admin IN SCHEMA "c_Bibliothèque" GRANT ALL ON TABLES TO "g_ASGARD rec*1" ;
    ALTER DEFAULT PRIVILEGES IN SCHEMA "c_Bibliothèque" GRANT ALL ON SEQUENCES TO "g_ASGARD rec*1" ;
    ALTER DEFAULT PRIVILEGES FOR ROLE g_admin IN SCHEMA "c_Bibliothèque" GRANT ALL ON FUNCTIONS TO "g_ASGARD rec*1" ;
    ALTER DEFAULT PRIVILEGES FOR ROLE g_admin IN SCHEMA "c_Bibliothèque" GRANT ALL ON TYPES TO "g_ASGARD rec*1" ;
    ALTER DEFAULT PRIVILEGES FOR ROLE g_admin IN SCHEMA "c_Bibliothèque" GRANT SELECT ON TABLES TO public ;
    
    -- #1
    BEGIN
    SET ROLE g_admin ;
    
    PERFORM z_asgard.asgard_initialise_schema('c_Bibliothèque') ;
    
    EXECUTE 'SET ROLE ' || utilisateur ;
    RETURN False ;
    
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                                e_detl = PG_EXCEPTION_DETAIL ;
                                
        r := (e_mssg ~ 'FIS6[.]' OR e_detl ~ 'FIS6[.]' OR False) ;
        RAISE NOTICE '48b-1 > %', r::text ;
    END ;
    
    -- #2
    PERFORM z_asgard.asgard_initialise_schema('c_Bibliothèque') ;
    
    SELECT
        count(*) = 0
        INTO STRICT b
        FROM pg_default_acl
        WHERE defaclnamespace = quote_ident('c_Bibliothèque')::regnamespace::oid ;
    
    r := r AND b ;
    RAISE NOTICE '48b-2 > %', r::text ;   

    ------ initialisation lors du référencement ------
    CREATE SCHEMA "c_Librairie" ;
    PERFORM z_asgard_admin.asgard_sortie_gestion_schema('"c_Librairie"') ;
    
    SET ROLE g_admin ;
    ALTER DEFAULT PRIVILEGES IN SCHEMA "c_Bibliothèque" GRANT ALL ON TABLES TO "g_ASGARD rec*1" ;
    
    -- #3
    PERFORM z_asgard.asgard_initialise_schema('c_Bibliothèque') ;
    
    SELECT
        count(*) = 0
        INTO STRICT b 
        FROM pg_default_acl
        WHERE defaclnamespace = quote_ident('c_Bibliothèque')::regnamespace::oid ;
        
    r := r AND b ;
    RAISE NOTICE '48b-3 > %', r::text ; 
    
    EXECUTE 'SET ROLE ' || utilisateur ;
    
    DROP SCHEMA "c_Bibliothèque" ;
    DROP SCHEMA "c_Librairie" ;
    DROP ROLE "g_ASGARD rec*1" ;
    DELETE FROM z_asgard.gestion_schema_usr ;    

    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t048b() IS 'ASGARD recette. TEST : (asgard_initialise_schema) suppression des privilèges par défaut.' ;


-- FUNCTION: z_asgard_recette.t049()

CREATE OR REPLACE FUNCTION z_asgard_recette.t049()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
BEGIN

    CREATE ROLE g_asgard_rec1 ;

    CREATE SCHEMA c_librairie ;
    PERFORM z_asgard_admin.asgard_sortie_gestion_schema('c_librairie') ;
    ALTER DEFAULT PRIVILEGES IN SCHEMA c_librairie GRANT ALL ON TABLES TO g_asgard_rec1 ;
    CREATE TABLE c_librairie.journal_du_mur (id serial PRIMARY KEY, nom text) ;

    PERFORM z_asgard.asgard_initialise_schema('c_librairie', True) ;
    
    -- #1
    SELECT
        count(*) = 1
        INTO STRICT b 
        FROM pg_class
        WHERE relnamespace = quote_ident('c_librairie')::regnamespace::oid
            AND relname = 'journal_du_mur'
            AND array_to_string(relacl, ',') ~ ('^(.*[,])?' || z_asgard.asgard_role_trans_acl(quote_ident('g_asgard_rec1')::regrole)
                    || '[=][rwadDxt]{7}[/]') ;
                    
    r := b ;
    RAISE NOTICE '49-1 > %', r::text ; 
    
    -- #2
    SELECT
        count(*) = 1
        INTO STRICT b 
        FROM pg_default_acl
        WHERE defaclnamespace = quote_ident('c_librairie')::regnamespace::oid
            AND defaclobjtype = 'r'
            AND array_to_string(defaclacl, ',') ~ ('^(.*[,])?' || z_asgard.asgard_role_trans_acl(quote_ident('g_asgard_rec1')::regrole)
                    || '[=][rwadDxt]{7}[/]') ;
        
    r := r AND b ;
    RAISE NOTICE '49-2 > %', r::text ; 
    
    DROP SCHEMA c_librairie CASCADE ;
    DELETE FROM z_asgard.gestion_schema_usr ;
    DROP ROLE g_asgard_rec1 ;

    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t049() IS 'ASGARD recette. TEST : (asgard_initialise_schema) préservation des droits à l''import.' ;

-- FUNCTION: z_asgard_recette.t049b()

CREATE OR REPLACE FUNCTION z_asgard_recette.t049b()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
BEGIN

    CREATE ROLE "g_ASGARD rec*1" ;

    CREATE SCHEMA "c_Lib-rairie" ;
    PERFORM z_asgard_admin.asgard_sortie_gestion_schema('c_Lib-rairie') ;
    ALTER DEFAULT PRIVILEGES IN SCHEMA "c_Lib-rairie" GRANT ALL ON TABLES TO "g_ASGARD rec*1" ;
    CREATE TABLE "c_Lib-rairie"."Journal du mur !" (id serial PRIMARY KEY, nom text) ;

    PERFORM z_asgard.asgard_initialise_schema('c_Lib-rairie', True) ;
    
    -- #1
    SELECT
        count(*) = 1
        INTO STRICT b 
        FROM pg_class
        WHERE relnamespace = quote_ident('c_Lib-rairie')::regnamespace::oid
            AND relname = 'Journal du mur !'
            AND array_to_string(relacl, ',') ~ ('^(.*[,])?' || z_asgard.asgard_role_trans_acl(quote_ident('g_ASGARD rec*1')::regrole)
                    || '[=][rwadDxt]{7}[/]') ;
                    
    r := b ;
    RAISE NOTICE '49b-1 > %', r::text ; 
    
    -- #2
    SELECT
        count(*) = 1
        INTO STRICT b 
        FROM pg_default_acl
        WHERE defaclnamespace = quote_ident('c_Lib-rairie')::regnamespace::oid
            AND defaclobjtype = 'r'
            AND array_to_string(defaclacl, ',') ~ ('^(.*[,])?' || z_asgard.asgard_role_trans_acl(quote_ident('g_ASGARD rec*1')::regrole)
                    || '[=][rwadDxt]{7}[/]') ;
        
    r := r AND b ;
    RAISE NOTICE '49b-2 > %', r::text ; 
    
    DROP SCHEMA "c_Lib-rairie" CASCADE ;
    DELETE FROM z_asgard.gestion_schema_usr ;
    DROP ROLE "g_ASGARD rec*1" ;

    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t049b() IS 'ASGARD recette. TEST : (asgard_initialise_schema) préservation des droits à l''import.' ;


-- FUNCTION: z_asgard_recette.t050()

CREATE OR REPLACE FUNCTION z_asgard_recette.t050()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
BEGIN

    CREATE SCHEMA c_bibliotheque ;
    PERFORM z_asgard_admin.asgard_sortie_gestion_schema('c_bibliotheque') ;
    GRANT CREATE ON SCHEMA c_bibliotheque TO g_admin_ext ;
    
    INSERT INTO z_asgard.gestion_schema_usr (nom_schema, producteur, editeur, lecteur)
        VALUES ('c_bibliotheque', 'g_admin', 'g_admin_ext', 'g_consult') ;
        
    ------ en conservant les privilèges ------
    PERFORM z_asgard.asgard_initialise_schema('c_bibliotheque', 'True') ;
    
    -- #1
    SELECT
        count(*) = 1
        INTO STRICT b 
        FROM pg_namespace
        WHERE nspname = 'c_bibliotheque'
            AND array_to_string(nspacl, ',') ~ ('^(.*[,])?' || z_asgard.asgard_role_trans_acl(quote_ident('g_admin_ext')::regrole)
                    || '[=][UC]{2}[/]') ;
                    
    r := b ;
    RAISE NOTICE '50-1 > %', r::text ;
    
    -- #2
    SELECT
        count(*) = 1
        INTO STRICT b 
        FROM pg_namespace
        WHERE nspname = 'c_bibliotheque'
            AND array_to_string(nspacl, ',') ~ ('^(.*[,])?' || z_asgard.asgard_role_trans_acl(quote_ident('g_consult')::regrole)
                    || '[=]U[/]') ;
                    
    r := b ;
    RAISE NOTICE '50-2 > %', r::text ; 
    
    ------ en réinitialisant les privilèges ------
    PERFORM z_asgard_admin.asgard_sortie_gestion_schema('c_bibliotheque') ;
    INSERT INTO z_asgard.gestion_schema_usr (nom_schema, producteur, editeur, lecteur)
        VALUES ('c_bibliotheque', 'g_admin', 'g_admin_ext', 'public') ;
        
    PERFORM z_asgard.asgard_initialise_schema('c_bibliotheque', 'True') ;
    
    -- #3
    SELECT
        count(*) = 1
        INTO STRICT b 
        FROM pg_namespace
        WHERE nspname = 'c_bibliotheque'
            AND array_to_string(nspacl, ',') ~ ('^(.*[,])?' || z_asgard.asgard_role_trans_acl(quote_ident('g_admin_ext')::regrole)
                    || '[=]U[/]') ;
                    
    r := b ;
    RAISE NOTICE '50-3 > %', r::text ;
    
    -- #4
    SELECT
        count(*) = 1
        INTO STRICT b 
        FROM pg_namespace
        WHERE nspname = 'c_bibliotheque'
            AND array_to_string(nspacl, ',') ~ ('^(.*[,])?[=]U[/]') ;
                    
    r := b ;
    RAISE NOTICE '50-4 > %', r::text ; 
    
    DROP SCHEMA c_bibliotheque ;
    DELETE FROM z_asgard.gestion_schema_usr ;

    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t050() IS 'ASGARD recette. TEST : (asgard_initialise_schema) application des droits du lecteur et de l''éditeur lors du référencement d''un schéma pré-existant pré-référencé.' ;


-- FUNCTION: z_asgard_recette.t050b()

CREATE OR REPLACE FUNCTION z_asgard_recette.t050b()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
BEGIN

    CREATE ROLE "g_ADMIN" ;
    CREATE ROLE "g ADMIN ext" ;
    CREATE ROLE "g Consult !" ;

    CREATE SCHEMA "c_Bibliothèque" ;
    PERFORM z_asgard_admin.asgard_sortie_gestion_schema('c_Bibliothèque') ;
    GRANT CREATE ON SCHEMA "c_Bibliothèque" TO "g ADMIN ext" ;
    
    INSERT INTO z_asgard.gestion_schema_usr (nom_schema, producteur, editeur, lecteur)
        VALUES ('c_Bibliothèque', 'g_ADMIN', 'g ADMIN ext', 'g Consult !') ;
        
    ------ en conservant les privilèges ------
    PERFORM z_asgard.asgard_initialise_schema('c_Bibliothèque', 'True') ;
    
    -- #1
    SELECT
        count(*) = 1
        INTO STRICT b 
        FROM pg_namespace
        WHERE nspname = 'c_Bibliothèque'
            AND array_to_string(nspacl, ',') ~ ('^(.*[,])?' || z_asgard.asgard_role_trans_acl(quote_ident('g ADMIN ext')::regrole)
                    || '[=][UC]{2}[/]') ;
                    
    r := b ;
    RAISE NOTICE '50b-1 > %', r::text ;
    
    -- #2
    SELECT
        count(*) = 1
        INTO STRICT b 
        FROM pg_namespace
        WHERE nspname = 'c_Bibliothèque'
            AND array_to_string(nspacl, ',') ~ ('^(.*[,])?' || z_asgard.asgard_role_trans_acl(quote_ident('g Consult !')::regrole)
                    || '[=]U[/]') ;
                    
    r := b ;
    RAISE NOTICE '50b-2 > %', r::text ; 
    
    ------ en réinitialisant les privilèges ------
    PERFORM z_asgard_admin.asgard_sortie_gestion_schema('c_Bibliothèque') ;
    INSERT INTO z_asgard.gestion_schema_usr (nom_schema, producteur, editeur, lecteur)
        VALUES ('c_Bibliothèque', 'g_ADMIN', 'g ADMIN ext', 'public') ;
        
    PERFORM z_asgard.asgard_initialise_schema('c_Bibliothèque', 'True') ;
    
    -- #3
    SELECT
        count(*) = 1
        INTO STRICT b 
        FROM pg_namespace
        WHERE nspname = 'c_Bibliothèque'
            AND array_to_string(nspacl, ',') ~ ('^(.*[,])?' || z_asgard.asgard_role_trans_acl(quote_ident('g ADMIN ext')::regrole)
                    || '[=]U[/]') ;
                    
    r := b ;
    RAISE NOTICE '50b-3 > %', r::text ;
    
    -- #4
    SELECT
        count(*) = 1
        INTO STRICT b 
        FROM pg_namespace
        WHERE nspname = 'c_Bibliothèque'
            AND array_to_string(nspacl, ',') ~ ('^(.*[,])?[=]U[/]') ;
                    
    r := b ;
    RAISE NOTICE '50b-4 > %', r::text ; 
    
    DROP SCHEMA "c_Bibliothèque" ;
    DELETE FROM z_asgard.gestion_schema_usr ;
    
    DROP ROLE "g_ADMIN" ;
    DROP ROLE "g ADMIN ext" ;
    DROP ROLE "g Consult !" ;

    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t050b() IS 'ASGARD recette. TEST : (asgard_initialise_schema) application des droits du lecteur et de l''éditeur lors du référencement d''un schéma pré-existant pré-référencé.' ;


-- FUNCTION: z_asgard_recette.t051()

CREATE OR REPLACE FUNCTION z_asgard_recette.t051()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
   e_mssg text ;
   e_detl text ;
BEGIN

    CREATE ROLE g_asgard_rec_lec ;
    CREATE ROLE g_asgard_rec_edi ;
    CREATE ROLE g_asgard_rec_pro ;
    CREATE ROLE g_asgard_rec_orp ;

    CREATE SCHEMA c_bibliotheque AUTHORIZATION g_asgard_rec_pro ;
    UPDATE z_asgard.gestion_schema_usr
        SET editeur = 'g_asgard_rec_edi',
            lecteur = 'g_asgard_rec_lec'
        WHERE nom_schema = 'c_bibliotheque' ;
            
    CREATE VIEW c_bibliotheque.vue_du_mur AS (SELECT 'C''est haut !'::text AS observation) ;
    CREATE SEQUENCE c_bibliotheque.compteur ;
            
    PERFORM z_asgard.asgard_initialise_schema('z_asgard') ;
    PERFORM z_asgard.asgard_initialise_schema('z_asgard_admin') ;
    
    ------ désynchronisation des propriétaires ------
    ALTER EVENT TRIGGER asgard_on_alter_objet DISABLE ;
    ALTER VIEW c_bibliotheque.vue_du_mur OWNER TO g_asgard_rec_orp ;
    ALTER EVENT TRIGGER asgard_on_alter_objet ENABLE ;
    
    -- #1
    SELECT count(*) = 1
        INTO b
        FROM z_asgard_admin.asgard_diagnostic() ;
        
    r := b ;
    RAISE NOTICE '51-1 > %', r::text ; 
        
    -- #2
    SELECT count(*) = 1
        INTO b
        FROM z_asgard_admin.asgard_diagnostic(ARRAY['c_bibliotheque'])
        WHERE typ_objet = 'vue' AND nom_schema = 'c_bibliotheque'
            AND nom_objet = 'vue_du_mur' AND critique
            AND anomalie ~ 'propriétaire'
            AND strpos(anomalie, 'g_asgard_rec_orp') > 0
            AND strpos(anomalie, 'g_asgard_rec_pro') > 0 ;
            
    r := r AND b ;
    RAISE NOTICE '51-2 > %', r::text ;
    
    ------ droits manquants du propriétaire/producteur ------
    PERFORM z_asgard.asgard_initialise_schema('c_bibliotheque') ;
    REVOKE CREATE ON SCHEMA c_bibliotheque FROM g_asgard_rec_pro ;
    REVOKE DELETE ON TABLE c_bibliotheque.vue_du_mur FROM g_asgard_rec_pro ;
    
    -- #3
    SELECT count(*) = 2
        INTO b
        FROM z_asgard_admin.asgard_diagnostic() ;
        
    r := r AND b ;
    RAISE NOTICE '51-3 > %', r::text ; 
    
    -- #4
    SELECT count(*) = 1
        INTO b
        FROM z_asgard_admin.asgard_diagnostic(ARRAY['c_bibliotheque'])
        WHERE typ_objet = 'vue' AND nom_schema = 'c_bibliotheque'
            AND nom_objet = 'vue_du_mur' AND NOT critique
            AND anomalie ~ 'manquant'
            AND anomalie ~ 'DELETE'
            AND strpos(anomalie, 'g_asgard_rec_pro') > 0 ;
            
    r := r AND b ;
    RAISE NOTICE '51-4 > %', r::text ;
    
    -- #5
    SELECT count(*) = 1
        INTO b
        FROM z_asgard_admin.asgard_diagnostic(ARRAY['c_bibliotheque'])
        WHERE typ_objet = 'schéma' AND nom_schema = 'c_bibliotheque'
            AND nom_objet = 'c_bibliotheque' AND NOT critique
            AND anomalie ~ 'manquant'
            AND anomalie ~ 'propriétaire'
            AND anomalie ~ 'CREATE'
            AND strpos(anomalie, 'g_asgard_rec_pro') > 0 ;
            
    r := r AND b ;
    RAISE NOTICE '51-5 > %', r::text ;
    
    ------ droits manquants de l'éditeur ------
    PERFORM z_asgard.asgard_initialise_schema('c_bibliotheque') ;
    REVOKE UPDATE ON TABLE c_bibliotheque.vue_du_mur FROM g_asgard_rec_edi ;
    
    -- #6
    SELECT count(*) = 1
        INTO b
        FROM z_asgard_admin.asgard_diagnostic() ;
            
    r := r AND b ;
    RAISE NOTICE '51-6 > %', r::text ;
    
    -- #7
    SELECT count(*) = 1
        INTO b
        FROM z_asgard_admin.asgard_diagnostic(ARRAY['c_bibliotheque'])
        WHERE typ_objet = 'vue' AND nom_schema = 'c_bibliotheque'
            AND nom_objet = 'vue_du_mur' AND NOT critique
            AND anomalie ~ 'manquant'
            AND anomalie ~ 'UPDATE'
            AND strpos(anomalie, 'g_asgard_rec_edi') > 0 ;
            
    r := r AND b ;
    RAISE NOTICE '51-7 > %', r::text ;
    
    ------ droits manquants de l'éditeur (public) ------
    UPDATE z_asgard.gestion_schema_usr
        SET editeur = 'public'
        WHERE nom_schema = 'c_bibliotheque' ;
    
    -- #8
    SELECT count(*) = 1
        INTO b
        FROM z_asgard_admin.asgard_diagnostic() ;
            
    r := r AND b ;
    RAISE NOTICE '51-8 > %', r::text ;
    
    -- #9
    SELECT count(*) = 1
        INTO b
        FROM z_asgard_admin.asgard_diagnostic()
        WHERE typ_objet = 'vue' AND nom_schema = 'c_bibliotheque'
            AND nom_objet = 'vue_du_mur' AND NOT critique
            AND anomalie ~ 'manquant'
            AND anomalie ~ 'UPDATE'
            AND strpos(anomalie, 'public') > 0 ;
            
    r := r AND b ;
    RAISE NOTICE '51-9 > %', r::text ;
    
    
    ------ droits manquants du lecteur ------
    PERFORM z_asgard.asgard_initialise_schema('c_bibliotheque') ;
    REVOKE SELECT ON SEQUENCE c_bibliotheque.compteur FROM g_asgard_rec_lec ;
    
    -- #10
    SELECT count(*) = 1
        INTO b
        FROM z_asgard_admin.asgard_diagnostic() ;
            
    r := r AND b ;
    RAISE NOTICE '51-10 > %', r::text ;
    
    -- #11
    SELECT count(*) = 1
        INTO b
        FROM z_asgard_admin.asgard_diagnostic(ARRAY['c_bibliotheque'])
        WHERE typ_objet = 'séquence' AND nom_schema = 'c_bibliotheque'
            AND nom_objet = 'compteur' AND NOT critique
            AND anomalie ~ 'manquant'
            AND anomalie ~ 'SELECT'
            AND strpos(anomalie, 'g_asgard_rec_lec') > 0 ;
            
    r := r AND b ;
    RAISE NOTICE '51-11 > %', r::text ;
    
    ------ droits manquants du lecteur (public) -------
    UPDATE z_asgard.gestion_schema_usr
        SET editeur = 'g_asgard_rec_edi',
            lecteur = 'public'
        WHERE nom_schema = 'c_bibliotheque' ;
    
    -- #12
    SELECT count(*) = 1
        INTO b
        FROM z_asgard_admin.asgard_diagnostic() ;
            
    r := r AND b ;
    RAISE NOTICE '51-12 > %', r::text ;
    
    -- #13
    SELECT count(*) = 1
        INTO b
        FROM z_asgard_admin.asgard_diagnostic(ARRAY['c_bibliotheque'])
        WHERE typ_objet = 'séquence' AND nom_schema = 'c_bibliotheque'
            AND nom_objet = 'compteur' AND NOT critique
            AND anomalie ~ 'manquant'
            AND anomalie ~ 'SELECT'
            AND strpos(anomalie, 'public') > 0 ;
            
    r := r AND b ;
    RAISE NOTICE '51-13 > %', r::text ;
    
    ------ droits excédentaires ------
    PERFORM z_asgard.asgard_initialise_schema('c_bibliotheque') ;
    GRANT ALL ON SEQUENCE c_bibliotheque.compteur TO g_asgard_rec_orp ;
    GRANT UPDATE (observation) ON TABLE c_bibliotheque.vue_du_mur TO g_asgard_rec_orp ;
    
    -- #14
    SELECT count(*) = 4
        INTO b
        FROM z_asgard_admin.asgard_diagnostic() ;
            
    r := r AND b ;
    RAISE NOTICE '51-14 > %', r::text ;
    
    -- #15.1
    SELECT count(*) = 1
        INTO b
        FROM z_asgard_admin.asgard_diagnostic(ARRAY['c_bibliotheque'])
        WHERE typ_objet = 'séquence' AND nom_schema = 'c_bibliotheque'
            AND nom_objet = 'compteur' AND NOT critique
            AND anomalie ~ 'supplémentaire'
            AND anomalie ~ 'UPDATE'
            AND strpos(anomalie, 'g_asgard_rec_orp') > 0 ;
            
    r := r AND b ;
    RAISE NOTICE '51-15.1 > %', r::text ;
    
    -- #15.2
    SELECT count(*) = 1
        INTO b
        FROM z_asgard_admin.asgard_diagnostic(ARRAY['c_bibliotheque'])
        WHERE typ_objet = 'attribut' AND nom_schema = 'c_bibliotheque'
            AND nom_objet = 'vue_du_mur (observation)' AND NOT critique
            AND anomalie ~ 'supplémentaire'
            AND anomalie ~ 'UPDATE'
            AND strpos(anomalie, 'g_asgard_rec_orp') > 0 ;
            
    r := r AND b ;
    RAISE NOTICE '51-15.2 > %', r::text ;
    
    ------ droits excédentaires (public + lecteur) ------
    PERFORM z_asgard.asgard_initialise_schema('c_bibliotheque') ;
    GRANT ALL ON SEQUENCE c_bibliotheque.compteur TO public ;
    
    -- #16
    SELECT count(*) = 2
        INTO b
        FROM z_asgard_admin.asgard_diagnostic() ;
            
    r := r AND b ;
    RAISE NOTICE '51-16 > %', r::text ;
    
    -- #17
    SELECT count(*) = 1
        INTO b
        FROM z_asgard_admin.asgard_diagnostic(ARRAY['c_bibliotheque'])
        WHERE typ_objet = 'séquence' AND nom_schema = 'c_bibliotheque'
            AND nom_objet = 'compteur' AND NOT critique
            AND anomalie ~ 'supplémentaire'
            AND anomalie ~ 'UPDATE'
            AND strpos(anomalie, 'public') > 0 ;
            
    r := r AND b ;
    RAISE NOTICE '51-17 > %', r::text ;
   
    ------ privilèges par défaut ------
    PERFORM z_asgard.asgard_initialise_schema('c_bibliotheque') ;
    ALTER DEFAULT PRIVILEGES FOR ROLE g_asgard_rec_orp IN SCHEMA c_bibliotheque
        GRANT ALL ON TABLES TO g_asgard_rec_edi ;
    ALTER DEFAULT PRIVILEGES FOR ROLE g_asgard_rec_orp IN SCHEMA c_bibliotheque
        GRANT ALL ON FUNCTIONS TO g_asgard_rec_lec ;
    ALTER DEFAULT PRIVILEGES FOR ROLE g_asgard_rec_orp IN SCHEMA c_bibliotheque
        GRANT ALL ON SEQUENCES TO public ;         
    ALTER DEFAULT PRIVILEGES FOR ROLE g_asgard_rec_orp IN SCHEMA c_bibliotheque
        GRANT ALL ON TYPES TO g_asgard_rec_pro ;
        
    -- #18
    SELECT count(*) = 12
        INTO b
        FROM z_asgard_admin.asgard_diagnostic() ;
            
    r := r AND b ;
    RAISE NOTICE '51-18 > %', r::text ;
    
    -- #19
    SELECT count(*) = 3
        INTO b
        FROM z_asgard_admin.asgard_diagnostic(ARRAY['c_bibliotheque'])
        WHERE typ_objet = 'privilège par défaut' AND nom_schema = 'c_bibliotheque'
            AND nom_objet IS NULL AND NOT critique
            AND anomalie ~ 'séquence'
            AND anomalie ~ ANY(ARRAY['USAGE', 'SELECT', 'UPDATE'])
            AND strpos(anomalie, 'public') > 0 ;
            
    r := r AND b ;
    RAISE NOTICE '51-19 > %', r::text ;
    
    -- #20
    SELECT count(*) = 1
        INTO b
        FROM z_asgard_admin.asgard_diagnostic(ARRAY['c_bibliotheque'])
        WHERE typ_objet = 'privilège par défaut' AND nom_schema = 'c_bibliotheque'
            AND nom_objet IS NULL AND NOT critique
            AND anomalie ~ 'fonction'
            AND anomalie ~ 'EXECUTE'
            AND strpos(anomalie, 'g_asgard_rec_lec') > 0 ;
            
    r := r AND b ;
    RAISE NOTICE '51-20 > %', r::text ;
    
    ------ droits nécessaires à ASGARD ------
    -- la suppression du privilège SELECT de g_admin_ext sur
    -- gestion_schema n'est pas testée, car la fonction
    -- asgard_diagnostic ne fonctionne plus dans ce cas
    PERFORM z_asgard.asgard_initialise_schema('c_bibliotheque') ;
    
    REVOKE USAGE ON SCHEMA z_asgard_admin FROM g_admin_ext ;
    REVOKE UPDATE, DELETE, INSERT ON TABLE z_asgard_admin.gestion_schema FROM g_admin_ext ;
    REVOKE USAGE ON SCHEMA z_asgard FROM g_consult ;
    REVOKE SELECT ON TABLE z_asgard.gestion_schema_etr FROM g_consult ;
    REVOKE SELECT ON TABLE z_asgard.gestion_schema_usr FROM g_consult ;
    REVOKE SELECT ON TABLE z_asgard.asgardmenu_metadata FROM g_consult ;
    REVOKE SELECT ON TABLE z_asgard.asgardmanager_metadata FROM g_consult ;

    -- #21
    SELECT count(*) = 9
        INTO b
        FROM z_asgard_admin.asgard_diagnostic() ;
            
    r := r AND b ;
    RAISE NOTICE '51-21 > %', r::text ;
    
    -- #22
    SELECT count(*) = 9
        INTO b
        FROM z_asgard_admin.asgard_diagnostic(ARRAY['z_asgard', 'z_asgard_admin'])
            LEFT JOIN (
                VALUES
                ('z_asgard_admin', 'z_asgard_admin', 'schéma', 'USAGE', 'g_admin_ext'),
                ('z_asgard_admin', 'gestion_schema', 'table', 'INSERT', 'g_admin_ext'),
                ('z_asgard_admin', 'gestion_schema', 'table', 'UPDATE', 'g_admin_ext'),
                ('z_asgard_admin', 'gestion_schema', 'table', 'DELETE', 'g_admin_ext'),
                ('z_asgard', 'z_asgard', 'schéma', 'USAGE', 'g_consult'),
                ('z_asgard', 'gestion_schema_usr', 'vue', 'SELECT', 'g_consult'),
                ('z_asgard', 'gestion_schema_etr', 'vue', 'SELECT', 'g_consult'),
                ('z_asgard', 'asgardmenu_metadata', 'vue', 'SELECT', 'g_consult'),
                ('z_asgard', 'asgardmanager_metadata', 'vue', 'SELECT', 'g_consult')
            ) AS t (a_schema, a_objet, a_type, a_commande, a_role)
        ON typ_objet = a_type AND nom_schema = a_schema
            AND nom_objet = a_objet
            AND anomalie ~ a_commande
            AND strpos(anomalie, a_role) > 0
        WHERE critique AND anomalie ~ 'ASGARD' ;
            
    r := r AND b ;
    RAISE NOTICE '51-22 > %', r::text ;
    
    PERFORM z_asgard.asgard_initialise_schema('z_asgard') ;
    PERFORM z_asgard.asgard_initialise_schema('z_asgard_admin') ;
    PERFORM z_asgard_admin.asgard_sortie_gestion_schema('z_asgard') ;
    PERFORM z_asgard_admin.asgard_sortie_gestion_schema('z_asgard_admin') ;
    DROP SCHEMA c_bibliotheque CASCADE ;
    DELETE FROM z_asgard.gestion_schema_usr ;

    DROP ROLE g_asgard_rec_lec ;
    DROP ROLE g_asgard_rec_edi ;
    DROP ROLE g_asgard_rec_pro ;
    DROP ROLE g_asgard_rec_orp ;
    
    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                            e_detl = PG_EXCEPTION_DETAIL ;
    RAISE NOTICE '%', e_mssg
        USING DETAIL = e_detl ;
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t051() IS 'ASGARD recette. TEST : (asgard_diagnostic) repérage effectif des anomalies.' ;


-- FUNCTION: z_asgard_recette.t051b()

CREATE OR REPLACE FUNCTION z_asgard_recette.t051b()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
   e_mssg text ;
   e_detl text ;
BEGIN

    CREATE ROLE "g_ASGARD rec*LEC" ;
    CREATE ROLE "g_ASGARD_rec_EDI" ;
    CREATE ROLE "g_ASGARD_rec\PRO" ;
    CREATE ROLE "g_ASGARD REC&ORP" ;

    CREATE SCHEMA "c_Bibliothèque" AUTHORIZATION "g_ASGARD_rec\PRO" ;
    UPDATE z_asgard.gestion_schema_usr
        SET editeur = 'g_ASGARD_rec_EDI',
            lecteur = 'g_ASGARD rec*LEC'
        WHERE nom_schema = 'c_Bibliothèque' ;
            
    CREATE VIEW "c_Bibliothèque"."Vue du mur !" AS (SELECT 'C''est haut !'::text AS "OBServation :)") ;
    CREATE SEQUENCE "c_Bibliothèque"."$compteur$" ;
    
    ------ désynchronisation des propriétaires ------
    ALTER EVENT TRIGGER asgard_on_alter_objet DISABLE ;
    ALTER VIEW "c_Bibliothèque"."Vue du mur !" OWNER TO "g_ASGARD REC&ORP" ;
    ALTER EVENT TRIGGER asgard_on_alter_objet ENABLE ;
    
    -- #1
    SELECT count(*) = 1
        INTO b
        FROM z_asgard_admin.asgard_diagnostic() ;
        
    r := b ;
    RAISE NOTICE '51b-1 > %', r::text ; 
        
    -- #2
    SELECT count(*) = 1
        INTO b
        FROM z_asgard_admin.asgard_diagnostic(ARRAY['c_Bibliothèque'])
        WHERE typ_objet = 'vue' AND nom_schema = 'c_Bibliothèque'
            AND nom_objet = 'Vue du mur !' AND critique
            AND anomalie ~ 'propriétaire'
            AND strpos(anomalie, 'g_ASGARD REC&ORP') > 0
            AND strpos(anomalie, 'g_ASGARD_rec\PRO') > 0 ;
            
    r := r AND b ;
    RAISE NOTICE '51b-2 > %', r::text ;
    
    ------ droits manquants du propriétaire/producteur ------
    PERFORM z_asgard.asgard_initialise_schema('c_Bibliothèque') ;
    REVOKE CREATE ON SCHEMA "c_Bibliothèque" FROM "g_ASGARD_rec\PRO" ;
    REVOKE DELETE ON TABLE "c_Bibliothèque"."Vue du mur !" FROM "g_ASGARD_rec\PRO" ;
    
    -- #3
    SELECT count(*) = 2
        INTO b
        FROM z_asgard_admin.asgard_diagnostic() ;
        
    r := r AND b ;
    RAISE NOTICE '51b-3 > %', r::text ; 
    
    -- #4
    SELECT count(*) = 1
        INTO b
        FROM z_asgard_admin.asgard_diagnostic(ARRAY['c_Bibliothèque'])
        WHERE typ_objet = 'vue' AND nom_schema = 'c_Bibliothèque'
            AND nom_objet = 'Vue du mur !' AND NOT critique
            AND anomalie ~ 'manquant'
            AND anomalie ~ 'DELETE'
            AND strpos(anomalie, 'g_ASGARD_rec\PRO') > 0 ;
            
    r := r AND b ;
    RAISE NOTICE '51b-4 > %', r::text ;
    
    -- #5
    SELECT count(*) = 1
        INTO b
        FROM z_asgard_admin.asgard_diagnostic(ARRAY['c_Bibliothèque'])
        WHERE typ_objet = 'schéma' AND nom_schema = 'c_Bibliothèque'
            AND nom_objet = 'c_Bibliothèque' AND NOT critique
            AND anomalie ~ 'manquant'
            AND anomalie ~ 'propriétaire'
            AND anomalie ~ 'CREATE'
            AND strpos(anomalie, 'g_ASGARD_rec\PRO') > 0 ;
            
    r := r AND b ;
    RAISE NOTICE '51b-5 > %', r::text ;
    
    ------ droits manquants de l'éditeur ------
    PERFORM z_asgard.asgard_initialise_schema('c_Bibliothèque') ;
    REVOKE UPDATE ON TABLE "c_Bibliothèque"."Vue du mur !" FROM "g_ASGARD_rec_EDI" ;
    
    -- #6
    SELECT count(*) = 1
        INTO b
        FROM z_asgard_admin.asgard_diagnostic() ;
            
    r := r AND b ;
    RAISE NOTICE '51b-6 > %', r::text ;
    
    -- #7
    SELECT count(*) = 1
        INTO b
        FROM z_asgard_admin.asgard_diagnostic(ARRAY['c_Bibliothèque'])
        WHERE typ_objet = 'vue' AND nom_schema = 'c_Bibliothèque'
            AND nom_objet = 'Vue du mur !' AND NOT critique
            AND anomalie ~ 'manquant'
            AND anomalie ~ 'UPDATE'
            AND strpos(anomalie, 'g_ASGARD_rec_EDI') > 0 ;
            
    r := r AND b ;
    RAISE NOTICE '51b-7 > %', r::text ;
    
    ------ droits manquants de l'éditeur (public) ------
    UPDATE z_asgard.gestion_schema_usr
        SET editeur = 'public'
        WHERE nom_schema = 'c_Bibliothèque' ;
    
    -- #8
    SELECT count(*) = 1
        INTO b
        FROM z_asgard_admin.asgard_diagnostic() ;
            
    r := r AND b ;
    RAISE NOTICE '51b-8 > %', r::text ;
    
    -- #9
    SELECT count(*) = 1
        INTO b
        FROM z_asgard_admin.asgard_diagnostic(ARRAY['c_Bibliothèque'])
        WHERE typ_objet = 'vue' AND nom_schema = 'c_Bibliothèque'
            AND nom_objet = 'Vue du mur !' AND NOT critique
            AND anomalie ~ 'manquant'
            AND anomalie ~ 'UPDATE'
            AND strpos(anomalie, 'public') > 0 ;
            
    r := r AND b ;
    RAISE NOTICE '51b-9 > %', r::text ;
    
    
    ------ droits manquants du lecteur ------
    PERFORM z_asgard.asgard_initialise_schema('c_Bibliothèque') ;
    REVOKE SELECT ON SEQUENCE "c_Bibliothèque"."$compteur$" FROM "g_ASGARD rec*LEC" ;
    
    -- #10
    SELECT count(*) = 1
        INTO b
        FROM z_asgard_admin.asgard_diagnostic() ;
            
    r := r AND b ;
    RAISE NOTICE '51b-10 > %', r::text ;
    
    -- #11
    SELECT count(*) = 1
        INTO b
        FROM z_asgard_admin.asgard_diagnostic(ARRAY['c_Bibliothèque'])
        WHERE typ_objet = 'séquence' AND nom_schema = 'c_Bibliothèque'
            AND nom_objet = '$compteur$' AND NOT critique
            AND anomalie ~ 'manquant'
            AND anomalie ~ 'SELECT'
            AND strpos(anomalie, 'g_ASGARD rec*LEC') > 0 ;
            
    r := r AND b ;
    RAISE NOTICE '51b-11 > %', r::text ;
    
    ------ droits manquants du lecteur (public) -------
    UPDATE z_asgard.gestion_schema_usr
        SET editeur = 'g_ASGARD_rec_EDI',
            lecteur = 'public'
        WHERE nom_schema = 'c_Bibliothèque' ;
    
    -- #12
    SELECT count(*) = 1
        INTO b
        FROM z_asgard_admin.asgard_diagnostic() ;
            
    r := r AND b ;
    RAISE NOTICE '51b-12 > %', r::text ;
    
    -- #13
    SELECT count(*) = 1
        INTO b
        FROM z_asgard_admin.asgard_diagnostic(ARRAY['c_Bibliothèque'])
        WHERE typ_objet = 'séquence' AND nom_schema = 'c_Bibliothèque'
            AND nom_objet = '$compteur$' AND NOT critique
            AND anomalie ~ 'manquant'
            AND anomalie ~ 'SELECT'
            AND strpos(anomalie, 'public') > 0 ;
            
    r := r AND b ;
    RAISE NOTICE '51b-13 > %', r::text ;
    
    ------ droits excédentaires ------
    PERFORM z_asgard.asgard_initialise_schema('c_Bibliothèque') ;
    GRANT ALL ON SEQUENCE "c_Bibliothèque"."$compteur$" TO "g_ASGARD REC&ORP" ;
    GRANT UPDATE ("OBServation :)") ON TABLE "c_Bibliothèque"."Vue du mur !" TO "g_ASGARD REC&ORP" ;
    
    -- #14
    SELECT count(*) = 4
        INTO b
        FROM z_asgard_admin.asgard_diagnostic() ;
            
    r := r AND b ;
    RAISE NOTICE '51b-14 > %', r::text ;
    
    -- #15.1
    SELECT count(*) = 1
        INTO b
        FROM z_asgard_admin.asgard_diagnostic(ARRAY['c_Bibliothèque'])
        WHERE typ_objet = 'séquence' AND nom_schema = 'c_Bibliothèque'
            AND nom_objet = '$compteur$' AND NOT critique
            AND anomalie ~ 'supplémentaire'
            AND anomalie ~ 'UPDATE'
            AND strpos(anomalie, 'g_ASGARD REC&ORP') > 0 ;
            
    r := r AND b ;
    RAISE NOTICE '51b-15.1 > %', r::text ;
    
    -- #15.2
    SELECT count(*) = 1
        INTO b
        FROM z_asgard_admin.asgard_diagnostic(ARRAY['c_Bibliothèque'])
        WHERE typ_objet = 'attribut' AND nom_schema = 'c_Bibliothèque'
            AND nom_objet = 'Vue du mur ! (OBServation :))' AND NOT critique
            AND anomalie ~ 'supplémentaire'
            AND anomalie ~ 'UPDATE'
            AND strpos(anomalie, 'g_ASGARD REC&ORP') > 0 ;
            
    r := r AND b ;
    RAISE NOTICE '51b-15.2 > %', r::text ;
    
    ------ droits excédentaires (public + lecteur) ------
    PERFORM z_asgard.asgard_initialise_schema('c_Bibliothèque') ;
    GRANT ALL ON SEQUENCE "c_Bibliothèque"."$compteur$" TO public ;
    
    -- #16
    SELECT count(*) = 2
        INTO b
        FROM z_asgard_admin.asgard_diagnostic() ;
            
    r := r AND b ;
    RAISE NOTICE '51b-16 > %', r::text ;
    
    -- #17
    SELECT count(*) = 1
        INTO b
        FROM z_asgard_admin.asgard_diagnostic(ARRAY['c_Bibliothèque'])
        WHERE typ_objet = 'séquence' AND nom_schema = 'c_Bibliothèque'
            AND nom_objet = '$compteur$' AND NOT critique
            AND anomalie ~ 'supplémentaire'
            AND anomalie ~ 'UPDATE'
            AND strpos(anomalie, 'public') > 0 ;
            
    r := r AND b ;
    RAISE NOTICE '51b-17 > %', r::text ;
   
    ------ privilèges par défaut ------
    PERFORM z_asgard.asgard_initialise_schema('c_Bibliothèque') ;
    ALTER DEFAULT PRIVILEGES FOR ROLE "g_ASGARD REC&ORP" IN SCHEMA "c_Bibliothèque"
        GRANT ALL ON TABLES TO "g_ASGARD_rec_EDI" ;
    ALTER DEFAULT PRIVILEGES FOR ROLE "g_ASGARD REC&ORP" IN SCHEMA "c_Bibliothèque"
        GRANT ALL ON FUNCTIONS TO "g_ASGARD rec*LEC" ;
    ALTER DEFAULT PRIVILEGES FOR ROLE "g_ASGARD REC&ORP" IN SCHEMA "c_Bibliothèque"
        GRANT ALL ON SEQUENCES TO public ;         
    ALTER DEFAULT PRIVILEGES FOR ROLE "g_ASGARD REC&ORP" IN SCHEMA "c_Bibliothèque"
        GRANT ALL ON TYPES TO "g_ASGARD_rec\PRO" ;
        
    -- #18
    SELECT count(*) = 12
        INTO b
        FROM z_asgard_admin.asgard_diagnostic() ;
            
    r := r AND b ;
    RAISE NOTICE '51b-18 > %', r::text ;
    
    -- #19
    SELECT count(*) = 3
        INTO b
        FROM z_asgard_admin.asgard_diagnostic(ARRAY['c_Bibliothèque'])
        WHERE typ_objet = 'privilège par défaut' AND nom_schema = 'c_Bibliothèque'
            AND nom_objet IS NULL AND NOT critique
            AND anomalie ~ 'séquence'
            AND anomalie ~ ANY(ARRAY['USAGE', 'SELECT', 'UPDATE'])
            AND strpos(anomalie, 'public') > 0 ;
            
    r := r AND b ;
    RAISE NOTICE '51b-19 > %', r::text ;
    
    -- #20
    SELECT count(*) = 1
        INTO b
        FROM z_asgard_admin.asgard_diagnostic(ARRAY['c_Bibliothèque'])
        WHERE typ_objet = 'privilège par défaut' AND nom_schema = 'c_Bibliothèque'
            AND nom_objet IS NULL AND NOT critique
            AND anomalie ~ 'fonction'
            AND anomalie ~ 'EXECUTE'
            AND strpos(anomalie, 'g_ASGARD rec*LEC') > 0 ;
            
    r := r AND b ;
    RAISE NOTICE '51b-20 > %', r::text ;
    
    DROP SCHEMA "c_Bibliothèque" CASCADE ;
    DELETE FROM z_asgard.gestion_schema_usr ;

    DROP ROLE "g_ASGARD rec*LEC" ;
    DROP ROLE "g_ASGARD_rec_EDI" ;
    DROP ROLE "g_ASGARD_rec\PRO" ;
    DROP ROLE "g_ASGARD REC&ORP" ;
    
    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                            e_detl = PG_EXCEPTION_DETAIL ;
    RAISE NOTICE '%', e_mssg
        USING DETAIL = e_detl ;
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t051b() IS 'ASGARD recette. TEST : (asgard_diagnostic) repérage effectif des anomalies.' ;


-- FUNCTION: z_asgard_recette.t052()

CREATE OR REPLACE FUNCTION z_asgard_recette.t052()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
   v int := 1 ;
   o text := 'c_bibliotheque' ;
   c text := 'c_librairie' ;
   t text ;
   e_mssg text ;
   e_detl text ;
BEGIN

    CREATE ROLE g_asgard_rec1 ;
    CREATE ROLE g_asgard_rec2 ;

    CREATE SCHEMA c_bibliotheque AUTHORIZATION g_asgard_rec1 ;
    CREATE SCHEMA c_librairie AUTHORIZATION g_asgard_rec2 ;
    
    ------ création des objets ------
    CREATE SEQUENCE c_bibliotheque.compteur ;
    
    IF current_setting('server_version_num')::int >= 100000
    THEN
        EXECUTE 'CREATE TABLE c_bibliotheque.journal_du_mur
            (id int DEFAULT nextval(''c_bibliotheque.compteur''::regclass), jour date, entree text, auteur text)
            PARTITION BY LIST (auteur)' ;
            
        EXECUTE 'CREATE TABLE c_bibliotheque.journal_du_mur_jon
            PARTITION OF c_bibliotheque.journal_du_mur
            FOR VALUES IN (''Jon Snow'')' ;
        EXECUTE 'CREATE TABLE c_bibliotheque.journal_du_mur_ingrid
            PARTITION OF c_bibliotheque.journal_du_mur
            FOR VALUES IN (''Ingrid'')' ;
    ELSE
        CREATE TABLE c_bibliotheque.journal_du_mur
            (id int DEFAULT nextval('c_bibliotheque.compteur'::regclass), jour date, entree text, auteur text) ;
    END IF ;
    
    CREATE VIEW c_bibliotheque.entree_du_jour AS (SELECT * FROM c_bibliotheque.journal_du_mur WHERE jour = now()::date) ;
    CREATE MATERIALIZED VIEW c_bibliotheque.histoire AS (SELECT * FROM c_bibliotheque.journal_du_mur WHERE jour < now()::date) ;
    
    CREATE TYPE c_bibliotheque.intervalle AS (d int, f int) ;
    
    CREATE FUNCTION c_bibliotheque.cherche_intervalle_sfunc(c_bibliotheque.intervalle, int)
        RETURNS c_bibliotheque.intervalle
        AS $$ SELECT LEAST($1.d, $2), GREATEST($1.f, $2) $$
        LANGUAGE SQL ;

    CREATE AGGREGATE c_bibliotheque.cherche_intervalle(int) (
        SFUNC = c_bibliotheque.cherche_intervalle_sfunc,
        STYPE = c_bibliotheque.intervalle
        ) ;
        
    CREATE DOMAIN c_bibliotheque.chiffre_pair int
        CONSTRAINT chiffre_pair_check CHECK (VALUE > 0 AND VALUE % 2 = 0) ;
        
    CREATE SERVER serveur_bidon
        FOREIGN DATA WRAPPER postgres_fdw
        OPTIONS (host 'localhost', port '5432', dbname 'base_bidon') ;
    
    CREATE FOREIGN TABLE c_bibliotheque.table_distante (
        id integer NOT NULL,
        data text
        )
        SERVER serveur_bidon
        OPTIONS (schema_name 'schema_bidon', table_name 'table_bidon') ;

    ------ boucle sur les 6 variantes de la fonction ------
    WHILE v <= 6 
    LOOP
        
        RAISE NOTICE '-- v% - 1 ------------', v::text ;
        PERFORM z_asgard.asgard_deplace_obj(o, 'table_distante', 'foreign table', c, v) ;
        RAISE NOTICE '-- v% - 2 ------------', v::text ;
        PERFORM z_asgard.asgard_deplace_obj(o, 'chiffre_pair', 'domain', c, v) ;
        RAISE NOTICE '-- v% - 3 ------------', v::text ;
        PERFORM z_asgard.asgard_deplace_obj(o, 'cherche_intervalle(integer)', 'aggregate', c, v) ;
        RAISE NOTICE '-- v% - 4 ------------', v::text ;
        PERFORM z_asgard.asgard_deplace_obj(o, 'cherche_intervalle_sfunc(' || quote_ident(o) || '.intervalle,integer)', 'function', c, v) ;
        RAISE NOTICE '-- v% - 5 ------------', v::text ;
        PERFORM z_asgard.asgard_deplace_obj(o, 'intervalle', 'type', c, v) ;
        RAISE NOTICE '-- v% - 6 ------------', v::text ;
        PERFORM z_asgard.asgard_deplace_obj(o, 'histoire', 'materialized view', c, v) ;
        RAISE NOTICE '-- v% - 7 ------------', v::text ;
        PERFORM z_asgard.asgard_deplace_obj(o, 'entree_du_jour', 'view', c, v) ;
        
        RAISE NOTICE '-- v% - 8 ------------', v::text ;
        IF current_setting('server_version_num')::int >= 100000
        THEN
            PERFORM z_asgard.asgard_deplace_obj(o, 'journal_du_mur_jon', 'table', c, v) ;
        END IF ;
        
        RAISE NOTICE '-- v% - 9 ------------', v::text ;
        IF current_setting('server_version_num')::int >= 100000
        THEN
            PERFORM z_asgard.asgard_deplace_obj(o, 'journal_du_mur', 'partitioned table', c, v) ;
        END IF ;
        
        RAISE NOTICE '-- v% - 10 ------------', v::text ;
        PERFORM z_asgard.asgard_deplace_obj(o, 'compteur', 'sequence', c, v) ;
    
        t := o ;
        o := c ;
        c := t ;
        v := v + 1 ;
    
    END LOOP ;
    
    ------ suppression des objets ------
    DROP SCHEMA c_librairie CASCADE ;
    DROP SCHEMA c_bibliotheque CASCADE ;
    DELETE FROM z_asgard.gestion_schema_usr ;
    DROP SERVER serveur_bidon ;

    DROP ROLE g_asgard_rec1 ;
    DROP ROLE g_asgard_rec2 ;

    RETURN True ;
    
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                            e_detl = PG_EXCEPTION_DETAIL ;
    RAISE NOTICE '%', e_mssg
        USING DETAIL = e_detl ;
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t052() IS 'ASGARD recette. TEST : (asgard_deplace_obj) prise en charge de tous les types d''objets par toutes les variantes.' ;


-- FUNCTION: z_asgard_recette.t052b()

CREATE OR REPLACE FUNCTION z_asgard_recette.t052b()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
   v int := 1 ;
   o text := 'c_Bibliothèque' ;
   c text := 'c_Libr''airie' ;
   t text ;
   e_mssg text ;
   e_detl text ;
BEGIN

    CREATE ROLE "g_asgard rec*1" ;
    CREATE ROLE "g_asgardREC2" ;

    CREATE SCHEMA "c_Bibliothèque" AUTHORIZATION "g_asgard rec*1" ;
    CREATE SCHEMA "c_Libr'airie" AUTHORIZATION "g_asgardREC2" ;
    
    ------ création des objets ------
    CREATE SEQUENCE "c_Bibliothèque"."COMP~^teur" ;
    
    IF current_setting('server_version_num')::int >= 100000
    THEN
        EXECUTE 'CREATE TABLE "c_Bibliothèque"."Journal&du&mur"
            (id int DEFAULT nextval(''"c_Bibliothèque"."COMP~^teur"''::regclass), jour date, entree text, auteur text)
            PARTITION BY LIST (auteur)' ;
            
        EXECUTE 'CREATE TABLE "c_Bibliothèque"."journal du mur{jon}"
            PARTITION OF "c_Bibliothèque"."Journal&du&mur"
            FOR VALUES IN (''Jon Snow'')' ;
        EXECUTE 'CREATE TABLE "c_Bibliothèque"."Journal&du&mur{ingrid}"
            PARTITION OF "c_Bibliothèque"."Journal&du&mur"
            FOR VALUES IN (''Ingrid'')' ;
    ELSE
        CREATE TABLE "c_Bibliothèque"."Journal&du&mur"
            (id int DEFAULT nextval('"c_Bibliothèque"."COMP~^teur"'::regclass), jour date, entree text, auteur text) ;
    END IF ;
    
    CREATE VIEW "c_Bibliothèque"."entrée du jour" AS (SELECT * FROM "c_Bibliothèque"."Journal&du&mur" WHERE jour = now()::date) ;
    CREATE MATERIALIZED VIEW "c_Bibliothèque"."Histoire" AS (SELECT * FROM "c_Bibliothèque"."Journal&du&mur" WHERE jour < now()::date) ;
    
    CREATE TYPE "c_Bibliothèque"."inter-valle" AS (d int, f int) ;
    
    CREATE FUNCTION "c_Bibliothèque"."cherche intervalle*sfunc"("c_Bibliothèque"."inter-valle", int)
        RETURNS "c_Bibliothèque"."inter-valle"
        AS $$ SELECT LEAST($1.d, $2), GREATEST($1.f, $2) $$
        LANGUAGE SQL ;

    CREATE AGGREGATE "c_Bibliothèque"."CHERCHE_INTERVALLE"(int) (
        SFUNC = "c_Bibliothèque"."cherche intervalle*sfunc",
        STYPE = "c_Bibliothèque"."inter-valle"
        ) ;
        
    CREATE DOMAIN "c_Bibliothèque"."Chiffre$pair" int
        CONSTRAINT "Chiffre$pair_check" CHECK (VALUE > 0 AND VALUE % 2 = 0) ;
        
    CREATE SERVER serveur_bidon
        FOREIGN DATA WRAPPER postgres_fdw
        OPTIONS (host 'localhost', port '5432', dbname 'base_bidon') ;
    
    CREATE FOREIGN TABLE "c_Bibliothèque"."table distante" (
        id integer NOT NULL,
        data text
        )
        SERVER serveur_bidon
        OPTIONS (schema_name 'schema_bidon', table_name 'table_bidon') ;

    ------ boucle sur les 6 variantes de la fonction ------
    WHILE v <= 6 
    LOOP
    
        RAISE NOTICE '-- v% - 1 ------------', v::text ;
        PERFORM z_asgard.asgard_deplace_obj(o, 'table distante', 'foreign table', c, v) ;
        RAISE NOTICE '-- v% - 2 ------------', v::text ;
        PERFORM z_asgard.asgard_deplace_obj(o, 'Chiffre$pair', 'domain', c, v) ;
        RAISE NOTICE '-- v% - 3 ------------', v::text ;
        PERFORM z_asgard.asgard_deplace_obj(o, '"CHERCHE_INTERVALLE"(integer)', 'aggregate', c, v) ;
        RAISE NOTICE '-- v% - 4 ------------', v::text ;
        PERFORM z_asgard.asgard_deplace_obj(o, '"cherche intervalle*sfunc"(' || quote_ident(o) || '."inter-valle",integer)', 'function', c, v) ;
        RAISE NOTICE '-- v% - 5 ------------', v::text ;
        PERFORM z_asgard.asgard_deplace_obj(o, 'inter-valle', 'type', c, v) ;
        RAISE NOTICE '-- v% - 6 ------------', v::text ;
        PERFORM z_asgard.asgard_deplace_obj(o, 'Histoire', 'materialized view', c, v) ;
        RAISE NOTICE '-- v% - 7 ------------', v::text ;
        PERFORM z_asgard.asgard_deplace_obj(o, 'entrée du jour', 'view', c, v) ;
        
        RAISE NOTICE '-- v% - 8 ------------', v::text ;
        IF current_setting('server_version_num')::int >= 100000
        THEN
            PERFORM z_asgard.asgard_deplace_obj(o, 'journal du mur{jon}', 'table', c, v) ;
        END IF ;
        
        RAISE NOTICE '-- v% - 9 ------------', v::text ;
        IF current_setting('server_version_num')::int >= 100000
        THEN
            PERFORM z_asgard.asgard_deplace_obj(o, 'Journal&du&mur', 'partitioned table', c, v) ;
        END IF ;
        
        RAISE NOTICE '-- v% - 10 ------------', v::text ;
        PERFORM z_asgard.asgard_deplace_obj(o, 'COMP~^teur', 'sequence', c, v) ;
    
        t := o ;
        o := c ;
        c := t ;
        v := v + 1 ;
    
    END LOOP ;
    
    ------ suppression des objets ------
    DROP SCHEMA "c_Libr'airie" CASCADE ;
    DROP SCHEMA "c_Bibliothèque" CASCADE ;
    DELETE FROM z_asgard.gestion_schema_usr ;
    DROP SERVER serveur_bidon ;
    
    DROP ROLE "g_asgard rec*1" ;
    DROP ROLE "g_asgardREC2" ;

    RETURN True ;
    
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                            e_detl = PG_EXCEPTION_DETAIL ;
    RAISE NOTICE '%', e_mssg
        USING DETAIL = e_detl ;
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t052b() IS 'ASGARD recette. TEST : (asgard_deplace_obj) prise en charge de tous les types d''objets par toutes les variantes.' ;


-- FUNCTION: z_asgard_recette.t053()

CREATE OR REPLACE FUNCTION z_asgard_recette.t053()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
    r boolean ;
    e_mssg text ;
    e_detl text ;
BEGIN

    CREATE ROLE g_asgard_rec1 ;

    CREATE SCHEMA c_bibliotheque AUTHORIZATION g_asgard_rec1 ;
    UPDATE z_asgard.gestion_schema_usr
        SET editeur = 'g_asgard_rec2',
            lecteur = 'public'
        WHERE nom_schema = 'c_bibliotheque' ;
    
    ------ création des objets ------
    ALTER EVENT TRIGGER asgard_on_create_objet DISABLE ;
    
    CREATE SEQUENCE c_bibliotheque.compteur ;
    REVOKE USAGE ON SEQUENCE c_bibliotheque.compteur FROM g_asgard_rec1 ;
    
    IF current_setting('server_version_num')::int >= 100000
    THEN
        EXECUTE 'CREATE TABLE c_bibliotheque.journal_du_mur
            (id int DEFAULT nextval(''c_bibliotheque.compteur''::regclass), jour date, entree text, auteur text)
            PARTITION BY LIST (auteur)' ;
        GRANT ALL ON TABLE c_bibliotheque.journal_du_mur TO g_asgard_rec2 ;
            
        EXECUTE 'CREATE TABLE c_bibliotheque.journal_du_mur_jon
            PARTITION OF c_bibliotheque.journal_du_mur
            FOR VALUES IN (''Jon Snow'')' ;
        EXECUTE 'CREATE TABLE c_bibliotheque.journal_du_mur_ingrid
            PARTITION OF c_bibliotheque.journal_du_mur
            FOR VALUES IN (''Ingrid'')' ;
        REVOKE SELECT ON TABLE c_bibliotheque.journal_du_mur_jon FROM public ;
    ELSE
        CREATE TABLE c_bibliotheque.journal_du_mur
            (id int DEFAULT nextval('c_bibliotheque.compteur'::regclass), jour date, entree text, auteur text) ;
    END IF ;
    
    CREATE VIEW c_bibliotheque.entree_du_jour AS (SELECT * FROM c_bibliotheque.journal_du_mur WHERE jour = now()::date) ;
    REVOKE UPDATE ON TABLE c_bibliotheque.entree_du_jour FROM g_asgard_rec2 ;
    
    CREATE MATERIALIZED VIEW c_bibliotheque.histoire AS (SELECT * FROM c_bibliotheque.journal_du_mur WHERE jour < now()::date) ;
    GRANT TRIGGER ON TABLE c_bibliotheque.histoire TO g_asgard_rec2 ;
    
    CREATE TYPE c_bibliotheque.intervalle AS (d int, f int) ;
    GRANT USAGE ON TYPE c_bibliotheque.intervalle TO g_asgard_rec2 ;
    
    CREATE FUNCTION c_bibliotheque.cherche_intervalle_sfunc(c_bibliotheque.intervalle, int)
        RETURNS c_bibliotheque.intervalle
        AS $$ SELECT LEAST($1.d, $2), GREATEST($1.f, $2) $$
        LANGUAGE SQL ;
    GRANT EXECUTE ON FUNCTION c_bibliotheque.cherche_intervalle_sfunc(c_bibliotheque.intervalle, int) TO g_asgard_rec2 ;

    CREATE AGGREGATE c_bibliotheque.cherche_intervalle(int) (
        SFUNC = c_bibliotheque.cherche_intervalle_sfunc,
        STYPE = c_bibliotheque.intervalle
        ) ;
    REVOKE EXECUTE ON FUNCTION c_bibliotheque.cherche_intervalle(int) FROM public ;
        
    CREATE DOMAIN c_bibliotheque.chiffre_pair int
        CONSTRAINT chiffre_pair_check CHECK (VALUE > 0 AND VALUE % 2 = 0) ;
    REVOKE USAGE ON DOMAIN c_bibliotheque.chiffre_pair FROM public ;
        
    CREATE SERVER serveur_bidon
        FOREIGN DATA WRAPPER postgres_fdw
        OPTIONS (host 'localhost', port '5432', dbname 'base_bidon') ;
    
    CREATE FOREIGN TABLE c_bibliotheque.table_distante (
        id integer NOT NULL,
        data text
        )
        SERVER serveur_bidon
        OPTIONS (schema_name 'schema_bidon', table_name 'table_bidon') ;
    GRANT ALL ON TABLE c_bibliotheque.table_distante TO public ;
        
    ALTER EVENT TRIGGER asgard_on_create_objet ENABLE ;

    ------ réinitialisation ------
    
    RAISE NOTICE '-- 1 ------------' ;
    PERFORM z_asgard.asgard_initialise_obj('c_bibliotheque', 'table_distante', 'foreign table') ;
    RAISE NOTICE '-- 2 ------------' ;
    PERFORM z_asgard.asgard_initialise_obj('c_bibliotheque', 'chiffre_pair', 'domain') ;
    RAISE NOTICE '-- 3 ------------' ;
    PERFORM z_asgard.asgard_initialise_obj('c_bibliotheque', 'cherche_intervalle(integer)', 'aggregate') ;
    RAISE NOTICE '-- 4 ------------' ;
    PERFORM z_asgard.asgard_initialise_obj('c_bibliotheque', 'cherche_intervalle_sfunc(c_bibliotheque.intervalle,integer)', 'function') ;
    RAISE NOTICE '-- 5 ------------' ;
    PERFORM z_asgard.asgard_initialise_obj('c_bibliotheque', 'intervalle', 'type') ;
    RAISE NOTICE '-- 6 ------------' ;
    PERFORM z_asgard.asgard_initialise_obj('c_bibliotheque', 'histoire', 'materialized view') ;
    RAISE NOTICE '-- 7 ------------' ;
    PERFORM z_asgard.asgard_initialise_obj('c_bibliotheque', 'entree_du_jour', 'view') ;
    
    RAISE NOTICE '-- 8 ------------' ;
    IF current_setting('server_version_num')::int >= 100000
    THEN
        PERFORM z_asgard.asgard_initialise_obj('c_bibliotheque', 'journal_du_mur_jon', 'table') ;
        PERFORM z_asgard.asgard_initialise_obj('c_bibliotheque', 'journal_du_mur_ingrid', 'table') ;
    END IF ;
    
    RAISE NOTICE '-- 9 ------------' ;
    IF current_setting('server_version_num')::int >= 100000
    THEN
        PERFORM z_asgard.asgard_initialise_obj('c_bibliotheque', 'journal_du_mur', 'partitioned table') ;
    ELSE
        PERFORM z_asgard.asgard_initialise_obj('c_bibliotheque', 'journal_du_mur', 'table') ;
    END IF ;    

    RAISE NOTICE '-- 10 ------------' ;
    PERFORM z_asgard.asgard_initialise_obj('c_bibliotheque', 'compteur', 'sequence') ;  
    
    -- il devrait rester deux privilèges révoqués du pseudo-rôle public
    SELECT count(*) = 2
        INTO STRICT r
        FROM z_asgard_admin.asgard_diagnostic() ;
    
    ------ suppression des objets ------
    DROP SCHEMA c_bibliotheque CASCADE ;
    DELETE FROM z_asgard.gestion_schema_usr ;
    DROP SERVER serveur_bidon ;
    
    DROP ROLE g_asgard_rec1 ;
    DROP ROLE g_asgard_rec2 ;

    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                            e_detl = PG_EXCEPTION_DETAIL ;
    RAISE NOTICE '%', e_mssg
        USING DETAIL = e_detl ;
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t053() IS 'ASGARD recette. TEST : (asgard_initialise_obj) prise en charge de tous les types d''objets.' ;


-- FUNCTION: z_asgard_recette.t053b()

CREATE OR REPLACE FUNCTION z_asgard_recette.t053b()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   r boolean ;
   e_mssg text ;
   e_detl text ;
BEGIN

    CREATE ROLE "g_ASGARD rec:1" ;

    CREATE SCHEMA "c_Bibliothèque" AUTHORIZATION "g_ASGARD rec:1" ;
    UPDATE z_asgard.gestion_schema_usr
        SET editeur = 'g_ASGARD rec:2',
            lecteur = 'public'
        WHERE nom_schema = 'c_Bibliothèque' ;
    
    ------ création des objets ------
    ALTER EVENT TRIGGER asgard_on_create_objet DISABLE ;
    
    CREATE SEQUENCE "c_Bibliothèque"."COMP~^teur" ;
    
    IF current_setting('server_version_num')::int >= 100000
    THEN
        EXECUTE 'CREATE TABLE "c_Bibliothèque"."Journal&du&mur"
            (id int DEFAULT nextval(''"c_Bibliothèque"."COMP~^teur"''::regclass), jour date, entree text, auteur text)
            PARTITION BY LIST (auteur)' ;
        
        EXECUTE 'CREATE TABLE "c_Bibliothèque"."journal du mur{jon}"
            PARTITION OF "c_Bibliothèque"."Journal&du&mur"
            FOR VALUES IN (''Jon Snow'')' ;
        EXECUTE 'CREATE TABLE "c_Bibliothèque"."Journal&du&mur{ingrid}"
            PARTITION OF "c_Bibliothèque"."Journal&du&mur"
            FOR VALUES IN (''Ingrid'')' ;
    ELSE
        CREATE TABLE "c_Bibliothèque"."Journal&du&mur"
            (id int DEFAULT nextval('"c_Bibliothèque"."COMP~^teur"'::regclass), jour date, entree text, auteur text) ;
    END IF ;
    
    CREATE VIEW "c_Bibliothèque"."entrée du jour" AS (SELECT * FROM "c_Bibliothèque"."Journal&du&mur" WHERE jour = now()::date) ;
    CREATE MATERIALIZED VIEW "c_Bibliothèque"."Histoire" AS (SELECT * FROM "c_Bibliothèque"."Journal&du&mur" WHERE jour < now()::date) ;
    
    CREATE TYPE "c_Bibliothèque"."inter-valle" AS (d int, f int) ;
    
    CREATE FUNCTION "c_Bibliothèque"."cherche intervalle*sfunc"("c_Bibliothèque"."inter-valle", int)
        RETURNS "c_Bibliothèque"."inter-valle"
        AS $$ SELECT LEAST($1.d, $2), GREATEST($1.f, $2) $$
        LANGUAGE SQL ;

    CREATE AGGREGATE "c_Bibliothèque"."CHERCHE_INTERVALLE"(int) (
        SFUNC = "c_Bibliothèque"."cherche intervalle*sfunc",
        STYPE = "c_Bibliothèque"."inter-valle"
        ) ;
        
    CREATE DOMAIN "c_Bibliothèque"."Chiffre$pair" int
        CONSTRAINT "Chiffre$pair_check" CHECK (VALUE > 0 AND VALUE % 2 = 0) ;
        
    CREATE SERVER serveur_bidon
        FOREIGN DATA WRAPPER postgres_fdw
        OPTIONS (host 'localhost', port '5432', dbname 'base_bidon') ;
    
    CREATE FOREIGN TABLE "c_Bibliothèque"."table distante" (
        id integer NOT NULL,
        data text
        )
        SERVER serveur_bidon
        OPTIONS (schema_name 'schema_bidon', table_name 'table_bidon') ;
        
    ALTER EVENT TRIGGER asgard_on_create_objet ENABLE ;

    ------ réinitialisation ------
    
    RAISE NOTICE '-- 1 ------------' ;
    PERFORM z_asgard.asgard_initialise_obj('c_Bibliothèque', 'table distante', 'foreign table') ;
    RAISE NOTICE '-- 2 ------------' ;
    PERFORM z_asgard.asgard_initialise_obj('c_Bibliothèque', 'Chiffre$pair', 'domain') ;
    RAISE NOTICE '-- 3 ------------' ;
    PERFORM z_asgard.asgard_initialise_obj('c_Bibliothèque', '"CHERCHE_INTERVALLE"(integer)', 'aggregate') ;
    RAISE NOTICE '-- 4 ------------' ;
    PERFORM z_asgard.asgard_initialise_obj('c_Bibliothèque', '"cherche intervalle*sfunc"("c_Bibliothèque"."inter-valle",integer)', 'function') ;
    RAISE NOTICE '-- 5 ------------' ;
    PERFORM z_asgard.asgard_initialise_obj('c_Bibliothèque', 'inter-valle', 'type') ;
    RAISE NOTICE '-- 6 ------------' ;
    PERFORM z_asgard.asgard_initialise_obj('c_Bibliothèque', 'Histoire', 'materialized view') ;
    RAISE NOTICE '-- 7 ------------' ;
    PERFORM z_asgard.asgard_initialise_obj('c_Bibliothèque', 'entrée du jour', 'view') ;
    
    RAISE NOTICE '-- 8 ------------' ;
    IF current_setting('server_version_num')::int >= 100000
    THEN
        PERFORM z_asgard.asgard_initialise_obj('c_Bibliothèque', 'journal du mur{jon}', 'table') ;
        PERFORM z_asgard.asgard_initialise_obj('c_Bibliothèque', 'Journal&du&mur{ingrid}', 'table') ;
    END IF ;
    
    RAISE NOTICE '-- 9 ------------' ;
    IF current_setting('server_version_num')::int >= 100000
    THEN
        PERFORM z_asgard.asgard_initialise_obj('c_Bibliothèque', 'Journal&du&mur', 'partitioned table') ;
    ELSE
        PERFORM z_asgard.asgard_initialise_obj('c_Bibliothèque', 'Journal&du&mur', 'table') ;
    END IF ;
    
    RAISE NOTICE '-- 10 ------------' ;
    PERFORM z_asgard.asgard_initialise_obj('c_Bibliothèque', 'COMP~^teur', 'sequence') ;
    
    SELECT count(*) = 0
        INTO STRICT r
        FROM z_asgard_admin.asgard_diagnostic() ;
    
    ------ suppression des objets ------
    DROP SCHEMA "c_Bibliothèque" CASCADE ;
    DELETE FROM z_asgard.gestion_schema_usr ;
    DROP SERVER serveur_bidon ;
    
    DROP ROLE "g_ASGARD rec:1" ;
    DROP ROLE "g_ASGARD rec:2" ;

    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                            e_detl = PG_EXCEPTION_DETAIL ;
    RAISE NOTICE '%', e_mssg
        USING DETAIL = e_detl ;
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t053b() IS 'ASGARD recette. TEST : (asgard_initialise_obj) prise en charge de tous les types d''objets.' ;


-- FUNCTION: z_asgard_recette.t054()

CREATE OR REPLACE FUNCTION z_asgard_recette.t054()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
    r boolean ;
    e_mssg text ;
    e_detl text ;
BEGIN

    CREATE ROLE g_asgard_rec1 ;

    CREATE SCHEMA c_bibliotheque AUTHORIZATION g_asgard_rec1 ;
    UPDATE z_asgard.gestion_schema_usr
        SET editeur = 'g_asgard_rec2',
            lecteur = 'public'
        WHERE nom_schema = 'c_bibliotheque' ;
    
    ------ création des objets ------
    ALTER EVENT TRIGGER asgard_on_create_objet DISABLE ;
    
    CREATE SEQUENCE c_bibliotheque.compteur ;
    REVOKE USAGE ON SEQUENCE c_bibliotheque.compteur FROM g_asgard_rec1 ;
    
    IF current_setting('server_version_num')::int >= 100000
    THEN
        EXECUTE 'CREATE TABLE c_bibliotheque.journal_du_mur
            (id int DEFAULT nextval(''c_bibliotheque.compteur''::regclass), jour date, entree text, auteur text)
            PARTITION BY LIST (auteur)' ;
        GRANT ALL ON TABLE c_bibliotheque.journal_du_mur TO g_asgard_rec2 ;
            
        EXECUTE 'CREATE TABLE c_bibliotheque.journal_du_mur_jon
            PARTITION OF c_bibliotheque.journal_du_mur
            FOR VALUES IN (''Jon Snow'')' ;
        EXECUTE 'CREATE TABLE c_bibliotheque.journal_du_mur_ingrid
            PARTITION OF c_bibliotheque.journal_du_mur
            FOR VALUES IN (''Ingrid'')' ;
        REVOKE SELECT ON TABLE c_bibliotheque.journal_du_mur_jon FROM public ;
    ELSE
        CREATE TABLE c_bibliotheque.journal_du_mur
            (id int DEFAULT nextval('c_bibliotheque.compteur'::regclass), jour date, entree text, auteur text) ;
    END IF ;
    
    CREATE VIEW c_bibliotheque.entree_du_jour AS (SELECT * FROM c_bibliotheque.journal_du_mur WHERE jour = now()::date) ;
    REVOKE UPDATE ON TABLE c_bibliotheque.entree_du_jour FROM g_asgard_rec2 ;
    
    CREATE MATERIALIZED VIEW c_bibliotheque.histoire AS (SELECT * FROM c_bibliotheque.journal_du_mur WHERE jour < now()::date) ;
    GRANT TRIGGER ON TABLE c_bibliotheque.histoire TO g_asgard_rec2 ;
    
    CREATE TYPE c_bibliotheque.intervalle AS (d int, f int) ;
    GRANT USAGE ON TYPE c_bibliotheque.intervalle TO g_asgard_rec2 ;
    
    CREATE FUNCTION c_bibliotheque.cherche_intervalle_sfunc(c_bibliotheque.intervalle, int)
        RETURNS c_bibliotheque.intervalle
        AS $$ SELECT LEAST($1.d, $2), GREATEST($1.f, $2) $$
        LANGUAGE SQL ;
    GRANT EXECUTE ON FUNCTION c_bibliotheque.cherche_intervalle_sfunc(c_bibliotheque.intervalle, int) TO g_asgard_rec2 ;

    CREATE AGGREGATE c_bibliotheque.cherche_intervalle(int) (
        SFUNC = c_bibliotheque.cherche_intervalle_sfunc,
        STYPE = c_bibliotheque.intervalle
        ) ;
    REVOKE EXECUTE ON FUNCTION c_bibliotheque.cherche_intervalle(int) FROM public ;
        
    CREATE DOMAIN c_bibliotheque.chiffre_pair int
        CONSTRAINT chiffre_pair_check CHECK (VALUE > 0 AND VALUE % 2 = 0) ;
    REVOKE USAGE ON DOMAIN c_bibliotheque.chiffre_pair FROM public ;
        
    CREATE SERVER serveur_bidon
        FOREIGN DATA WRAPPER postgres_fdw
        OPTIONS (host 'localhost', port '5432', dbname 'base_bidon') ;
    
    CREATE FOREIGN TABLE c_bibliotheque.table_distante (
        id integer NOT NULL,
        data text
        )
        SERVER serveur_bidon
        OPTIONS (schema_name 'schema_bidon', table_name 'table_bidon') ;
    GRANT ALL ON TABLE c_bibliotheque.table_distante TO public ;
        
    ALTER EVENT TRIGGER asgard_on_create_objet ENABLE ;

    ------ réinitialisation ------
    
    PERFORM z_asgard.asgard_initialise_schema('c_bibliotheque') ;
    
    -- il devrait rester deux privilèges révoqués du pseudo-rôle public
    SELECT count(*) = 2
        INTO STRICT r
        FROM z_asgard_admin.asgard_diagnostic() ;
    
    ------ suppression des objets ------
    DROP SCHEMA c_bibliotheque CASCADE ;
    DELETE FROM z_asgard.gestion_schema_usr ;
    DROP SERVER serveur_bidon ;
    
    DROP ROLE g_asgard_rec1 ;
    DROP ROLE g_asgard_rec2 ;

    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                            e_detl = PG_EXCEPTION_DETAIL ;
    RAISE NOTICE '%', e_mssg
        USING DETAIL = e_detl ;
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t054() IS 'ASGARD recette. TEST : (asgard_initialise_schema) prise en charge de tous les types d''objets avec ACL.' ;

-- FUNCTION: z_asgard_recette.t054b()

CREATE OR REPLACE FUNCTION z_asgard_recette.t054b()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
    r boolean ;
    e_mssg text ;
    e_detl text ;
BEGIN

    CREATE ROLE "g_asgard_rec1*" ;

    CREATE SCHEMA "c_Bibliothèque" AUTHORIZATION "g_asgard_rec1*" ;
    UPDATE z_asgard.gestion_schema_usr
        SET editeur = 'g_asgard REC#2',
            lecteur = 'public'
        WHERE nom_schema = 'c_Bibliothèque' ;
    
    ------ création des objets ------
    ALTER EVENT TRIGGER asgard_on_create_objet DISABLE ;
    
    CREATE SEQUENCE "c_Bibliothèque"."?Compteur?" ;
    REVOKE USAGE ON SEQUENCE "c_Bibliothèque"."?Compteur?" FROM "g_asgard_rec1*" ;
    
    IF current_setting('server_version_num')::int >= 100000
    THEN
        EXECUTE 'CREATE TABLE "c_Bibliothèque"."JournalDuMur"
            (id int DEFAULT nextval(''"c_Bibliothèque"."?Compteur?"''::regclass), jour date, entree text, auteur text)
            PARTITION BY LIST (auteur)' ;
        GRANT ALL ON TABLE "c_Bibliothèque"."JournalDuMur" TO "g_asgard REC#2" ;
            
        EXECUTE 'CREATE TABLE "c_Bibliothèque"."journal du mur | JON"
            PARTITION OF "c_Bibliothèque"."JournalDuMur"
            FOR VALUES IN (''Jon Snow'')' ;
        EXECUTE 'CREATE TABLE "c_Bibliothèque"."journal du mur | INGRID"
            PARTITION OF "c_Bibliothèque"."JournalDuMur"
            FOR VALUES IN (''Ingrid'')' ;
        REVOKE SELECT ON TABLE "c_Bibliothèque"."journal du mur | JON" FROM public ;
    ELSE
        CREATE TABLE "c_Bibliothèque"."JournalDuMur"
            (id int DEFAULT nextval('"c_Bibliothèque"."?Compteur?"'::regclass), jour date, entree text, auteur text) ;
    END IF ;
    
    CREATE VIEW "c_Bibliothèque"."--Entrée/du/jour" AS (SELECT * FROM "c_Bibliothèque"."JournalDuMur" WHERE jour = now()::date) ;
    REVOKE UPDATE ON TABLE "c_Bibliothèque"."--Entrée/du/jour" FROM "g_asgard REC#2" ;
    
    CREATE MATERIALIZED VIEW "c_Bibliothèque"."Histoire" AS (SELECT * FROM "c_Bibliothèque"."JournalDuMur" WHERE jour < now()::date) ;
    GRANT TRIGGER ON TABLE "c_Bibliothèque"."Histoire" TO "g_asgard REC#2" ;
    
    CREATE TYPE "c_Bibliothèque"."intervalle..." AS (d int, f int) ;
    GRANT USAGE ON TYPE "c_Bibliothèque"."intervalle..." TO "g_asgard REC#2" ;
    
    CREATE FUNCTION "c_Bibliothèque"."CHERCHE intervalle (sfunc)"("c_Bibliothèque"."intervalle...", int)
        RETURNS "c_Bibliothèque"."intervalle..."
        AS $$ SELECT LEAST($1.d, $2), GREATEST($1.f, $2) $$
        LANGUAGE SQL ;
    GRANT EXECUTE ON FUNCTION "c_Bibliothèque"."CHERCHE intervalle (sfunc)"("c_Bibliothèque"."intervalle...", int) TO "g_asgard REC#2" ;

    CREATE AGGREGATE "c_Bibliothèque"."ChercheIntervalle"(int) (
        SFUNC = "c_Bibliothèque"."CHERCHE intervalle (sfunc)",
        STYPE = "c_Bibliothèque"."intervalle..."
        ) ;
    REVOKE EXECUTE ON FUNCTION "c_Bibliothèque"."ChercheIntervalle"(int) FROM public ;
        
    CREATE DOMAIN "c_Bibliothèque"."Ch1ffr3 Père" int
        CONSTRAINT "Ch1ffr3 Père_check" CHECK (VALUE > 0 AND VALUE % 2 = 0) ;
    REVOKE USAGE ON DOMAIN "c_Bibliothèque"."Ch1ffr3 Père" FROM public ;
        
    CREATE SERVER serveur_bidon
        FOREIGN DATA WRAPPER postgres_fdw
        OPTIONS (host 'localhost', port '54b32', dbname 'base_bidon') ;
    
    CREATE FOREIGN TABLE "c_Bibliothèque"."[table distante]" (
        id integer NOT NULL,
        data text
        )
        SERVER serveur_bidon
        OPTIONS (schema_name 'schema_bidon', table_name 'table_bidon') ;
    GRANT ALL ON TABLE "c_Bibliothèque"."[table distante]" TO public ;
        
    ALTER EVENT TRIGGER asgard_on_create_objet ENABLE ;

    ------ réinitialisation ------
    
    PERFORM z_asgard.asgard_initialise_schema('c_Bibliothèque') ;
    
    -- il devrait rester deux privilèges révoqués du pseudo-rôle public
    SELECT count(*) = 2
        INTO STRICT r
        FROM z_asgard_admin.asgard_diagnostic() ;
    
    ------ suppression des objets ------
    DROP SCHEMA "c_Bibliothèque" CASCADE ;
    DELETE FROM z_asgard.gestion_schema_usr ;
    DROP SERVER serveur_bidon ;
    
    DROP ROLE "g_asgard_rec1*" ;
    DROP ROLE "g_asgard REC#2" ;

    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                            e_detl = PG_EXCEPTION_DETAIL ;
    RAISE NOTICE '%', e_mssg
        USING DETAIL = e_detl ;
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t054b() IS 'ASGARD recette. TEST : (asgard_initialise_schema) prise en charge de tous les types d''objets avec ACL.' ;


-- FUNCTION: z_asgard_recette.t055()

CREATE OR REPLACE FUNCTION z_asgard_recette.t055()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean := True ;
   variante record ;
   o_roles record ;
   c_roles record ;
   o text := 'c_bibliotheque' ;
   c text := 'c_librairie' ;
   t text ;
   e_mssg text ;
   e_detl text ;
   acl_idi text ;
   acl_ids text ;
BEGIN

    CREATE ROLE g_asgard_rec ;

    CREATE SCHEMA c_bibliotheque ;
    UPDATE z_asgard.gestion_schema_usr
        SET producteur = 'g_asgard_pro1',
            editeur = 'g_asgard_edi1',
            lecteur = 'g_asgard_lec1'
        WHERE nom_schema = 'c_bibliotheque' ;
    
    CREATE SCHEMA c_librairie ;
    UPDATE z_asgard.gestion_schema_usr
        SET producteur = 'g_asgard_pro2',
            editeur = 'g_asgard_edi2',
            lecteur = 'g_asgard_lec2'
        WHERE nom_schema = 'c_librairie' ;
    
    IF current_setting('server_version_num')::int >= 100000
    THEN
        EXECUTE 'CREATE TABLE c_bibliotheque.journal_du_mur(idi integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY, jour date, entree text)' ;
    ELSE
        CREATE TABLE c_bibliotheque.journal_du_mur(idi serial PRIMARY KEY, jour date, entree text) ;
    END IF ;
    CREATE TABLE c_bibliotheque.tours_de_garde(ids serial PRIMARY KEY, jour date, nom text) ;
    
    ------ application des 6 variantes -------
    FOR variante IN (
            SELECT *
                FROM unnest(
                    ARRAY[1,            2,              3,              4,              5,              6], -- numéro de variante
                    ARRAY[NULL,         NULL,           NULL,           NULL,           NULL,           NULL], -- droits du producteur du schéma de départ
                    ARRAY['[rw]{2}',   '[rwU]{3}',     '[rw]{2}',       '[rw]{2}',      '[rw]{2}',      '[rwU]{3}'], -- droits du producteur du schéma d'arrivée
                    ARRAY[NULL,         NULL,           NULL,           '[rU]{2}',      NULL,           NULL], -- droits de l'éditeur du schéma de départ
                    ARRAY['[rU]{2}',   '[rU]{2}',       '[rU]{2}',      NULL,           '[rU]{2}',      '[rU]{2}'], -- droits de l'éditeur du schéma d'arrivée
                    ARRAY[NULL,         NULL,           NULL,           '[rU]{2}',      NULL,           NULL], -- droits du lecteur du schéma de départ
                    ARRAY['[rU]{2}',    'r',            '[rU]{2}',      NULL,           'r',            'r'], -- droits du lecteur du schéma d'arrivée
                    ARRAY['[rw]{2}',    NULL,           NULL,           '[rw]{2}',      NULL,           '[rw]{2}']  -- droits de g_asgard_rec
                    ) AS t (n, dpro_o, dpro_c, dedi_o, dedi_c, dlec_o, dlec_c, drec)
                ORDER BY n
            )
    LOOP
        RAISE NOTICE '-- variante % ----------------', variante.n::text ;
        PERFORM z_asgard.asgard_initialise_schema(o) ;
        
        SELECT producteur, editeur, lecteur
            INTO o_roles
            FROM z_asgard.gestion_schema_usr
            WHERE nom_schema = o ;
            
        SELECT producteur, editeur, lecteur
            INTO c_roles
            FROM z_asgard.gestion_schema_usr
            WHERE nom_schema = c ;
        
        EXECUTE 'GRANT SELECT, UPDATE ON SEQUENCE ' || quote_ident(o) || '.' || quote_ident('journal_du_mur_idi_seq') || ' TO ' || quote_ident('g_asgard_rec') ;
        EXECUTE 'GRANT SELECT, UPDATE ON SEQUENCE ' || quote_ident(o) || '.' || quote_ident('tours_de_garde_ids_seq') || ' TO ' || quote_ident('g_asgard_rec') ;
        
        EXECUTE 'GRANT USAGE ON SEQUENCE ' || quote_ident(o) || '.' || quote_ident('journal_du_mur_idi_seq') || ' TO ' || quote_ident(o_roles.lecteur) ;
        EXECUTE 'GRANT USAGE ON SEQUENCE ' || quote_ident(o) || '.' || quote_ident('tours_de_garde_ids_seq') || ' TO ' || quote_ident(o_roles.lecteur) ;
        
        EXECUTE 'REVOKE USAGE ON SEQUENCE ' || quote_ident(o) || '.' || quote_ident('journal_du_mur_idi_seq') || ' FROM ' || quote_ident(o_roles.producteur) ;
        EXECUTE 'REVOKE USAGE ON SEQUENCE ' || quote_ident(o) || '.' || quote_ident('tours_de_garde_ids_seq') || ' FROM ' || quote_ident(o_roles.producteur) ;
        
        PERFORM z_asgard.asgard_deplace_obj(o, 'journal_du_mur', 'table', c, variante.n) ;
        PERFORM z_asgard.asgard_deplace_obj(o, 'tours_de_garde', 'table', c, variante.n) ;
        
        
        SELECT array_to_string(relacl, ',')
            INTO STRICT acl_idi
            FROM pg_class
            WHERE relnamespace::regnamespace::text = quote_ident(c)
                AND relname = 'journal_du_mur_idi_seq' ;
        
        SELECT array_to_string(relacl, ',')
            INTO STRICT acl_ids
            FROM pg_class
            WHERE relnamespace::regnamespace::text = quote_ident(c)
                AND relname = 'tours_de_garde_ids_seq' ;
  
        -- serial
        IF variante.dpro_o IS NULL AND acl_ids ~ ('^(.+[,])?' || z_asgard.asgard_role_trans_acl(quote_ident(o_roles.producteur)::regrole) || '[=]')
            OR variante.dpro_o IS NOT NULL AND NOT acl_ids ~ ('^' || z_asgard.asgard_role_trans_acl(quote_ident(o_roles.producteur)::regrole)
                            || '[=]' || variante.dpro_o
                            || '/' || z_asgard.asgard_role_trans_acl(quote_ident(c_roles.producteur)::regrole))
        THEN
            RAISE NOTICE 'acl_ids = %', acl_ids ;
            RAISE NOTICE 'ECHEC dpro_o' ;
            r := False ;
        END IF ;
        
        IF variante.dpro_c IS NULL AND acl_ids ~ ('^(.+[,])?' || z_asgard.asgard_role_trans_acl(quote_ident(c_roles.producteur)::regrole) || '[=]')
            OR variante.dpro_c IS NOT NULL AND NOT acl_ids ~ ('^(.+[,])?' || z_asgard.asgard_role_trans_acl(quote_ident(c_roles.producteur)::regrole)
                            || '[=]' || variante.dpro_c
                            || '/' || z_asgard.asgard_role_trans_acl(quote_ident(c_roles.producteur)::regrole))
        THEN
            RAISE NOTICE 'acl_ids = %', acl_ids ;
            RAISE NOTICE 'ECHEC dpro_c' ;
            r := False ;
        END IF ;
        
        IF variante.dedi_o IS NULL AND acl_ids ~ ('^(.+[,])?' || z_asgard.asgard_role_trans_acl(quote_ident(o_roles.editeur)::regrole) || '[=]')
            OR variante.dedi_o IS NOT NULL AND NOT acl_ids ~ ('^(.+[,])?' || z_asgard.asgard_role_trans_acl(quote_ident(o_roles.editeur)::regrole)
                            || '[=]' || variante.dedi_o
                            || '/' || z_asgard.asgard_role_trans_acl(quote_ident(c_roles.producteur)::regrole))
        THEN
            RAISE NOTICE 'acl_ids = %', acl_ids ;
            RAISE NOTICE 'ECHEC dedi_o' ;
            r := False ;
        END IF ;
        
        IF variante.dedi_c IS NULL AND acl_ids ~ ('^(.+[,])?' || z_asgard.asgard_role_trans_acl(quote_ident(c_roles.editeur)::regrole) || '[=]')
            OR variante.dedi_c IS NOT NULL AND NOT acl_ids ~ ('^(.+[,])?' || z_asgard.asgard_role_trans_acl(quote_ident(c_roles.editeur)::regrole)
                            || '[=]' || variante.dedi_c
                            || '/' || z_asgard.asgard_role_trans_acl(quote_ident(c_roles.producteur)::regrole))
        THEN
            RAISE NOTICE 'acl_ids = %', acl_ids ;
            RAISE NOTICE 'ECHEC dedi_c' ;
            r := False ;
        END IF ;
        
        IF variante.dlec_o IS NULL AND acl_ids ~ ('^(.+[,])?' || z_asgard.asgard_role_trans_acl(quote_ident(o_roles.lecteur)::regrole) || '[=]')
            OR variante.dlec_o IS NOT NULL AND NOT acl_ids ~ ('^(.+[,])?' || z_asgard.asgard_role_trans_acl(quote_ident(o_roles.lecteur)::regrole)
                            || '[=]' || variante.dlec_o
                            || '/' || z_asgard.asgard_role_trans_acl(quote_ident(c_roles.producteur)::regrole))
        THEN
            RAISE NOTICE 'acl_ids = %', acl_ids ;
            RAISE NOTICE 'ECHEC dlec_o' ;
            r := False ;
        END IF ;
        
        IF variante.dlec_c IS NULL AND acl_ids ~ ('^(.+[,])?' || z_asgard.asgard_role_trans_acl(quote_ident(c_roles.lecteur)::regrole) || '[=]')
            OR variante.dlec_c IS NOT NULL AND NOT acl_ids ~ ('^(.+[,])?' || z_asgard.asgard_role_trans_acl(quote_ident(c_roles.lecteur)::regrole)
                            || '[=]' || variante.dlec_c
                            || '/' || z_asgard.asgard_role_trans_acl(quote_ident(c_roles.producteur)::regrole))
        THEN
            RAISE NOTICE 'acl_ids = %', acl_ids ;
            RAISE NOTICE 'ECHEC dlec_c' ;
            r := False ;
        END IF ;
        
        IF variante.drec IS NULL AND acl_ids ~ ('^(.+[,])?' || z_asgard.asgard_role_trans_acl(quote_ident('g_asgard_rec')::regrole) || '[=]')
            OR variante.drec IS NOT NULL AND NOT acl_ids ~ ('^(.+[,])?' || z_asgard.asgard_role_trans_acl(quote_ident('g_asgard_rec')::regrole)
                            || '[=]' || variante.drec
                            || '/' || z_asgard.asgard_role_trans_acl(quote_ident(c_roles.producteur)::regrole))
        THEN
            RAISE NOTICE 'acl_ids = %', acl_ids ;
            RAISE NOTICE 'ECHEC drec' ;
            r := False ;
        END IF ;
        
        
        -- identity
        IF variante.dpro_o IS NULL AND acl_idi ~ ('^(.+[,])?' || z_asgard.asgard_role_trans_acl(quote_ident(o_roles.producteur)::regrole) || '[=]')
            OR variante.dpro_o IS NOT NULL AND NOT acl_idi ~ ('^' || z_asgard.asgard_role_trans_acl(quote_ident(o_roles.producteur)::regrole)
                            || '[=]' || variante.dpro_o
                            || '/' || z_asgard.asgard_role_trans_acl(quote_ident(c_roles.producteur)::regrole))
        THEN
            RAISE NOTICE 'acl_idi = %', acl_idi ;
            RAISE NOTICE 'ECHEC dpro_o' ;
            r := False ;
        END IF ;
        
        IF variante.dpro_c IS NULL AND acl_idi ~ ('^(.+[,])?' || z_asgard.asgard_role_trans_acl(quote_ident(c_roles.producteur)::regrole) || '[=]')
            OR variante.dpro_c IS NOT NULL AND NOT acl_idi ~ ('^(.+[,])?' || z_asgard.asgard_role_trans_acl(quote_ident(c_roles.producteur)::regrole)
                            || '[=]' || variante.dpro_c
                            || '/' || z_asgard.asgard_role_trans_acl(quote_ident(c_roles.producteur)::regrole))
        THEN
            RAISE NOTICE 'acl_idi = %', acl_idi ;
            RAISE NOTICE 'ECHEC dpro_c' ;
            r := False ;
        END IF ;
        
        IF variante.dedi_o IS NULL AND acl_idi ~ ('^(.+[,])?' || z_asgard.asgard_role_trans_acl(quote_ident(o_roles.editeur)::regrole) || '[=]')
            OR variante.dedi_o IS NOT NULL AND NOT acl_idi ~ ('^(.+[,])?' || z_asgard.asgard_role_trans_acl(quote_ident(o_roles.editeur)::regrole)
                            || '[=]' || variante.dedi_o
                            || '/' || z_asgard.asgard_role_trans_acl(quote_ident(c_roles.producteur)::regrole))
        THEN
            RAISE NOTICE 'acl_idi = %', acl_idi ;
            RAISE NOTICE 'ECHEC dedi_o' ;
            r := False ;
        END IF ;
        
        IF variante.dedi_c IS NULL AND acl_idi ~ ('^(.+[,])?' || z_asgard.asgard_role_trans_acl(quote_ident(c_roles.editeur)::regrole) || '[=]')
            OR variante.dedi_c IS NOT NULL AND NOT acl_idi ~ ('^(.+[,])?' || z_asgard.asgard_role_trans_acl(quote_ident(c_roles.editeur)::regrole)
                            || '[=]' || variante.dedi_c
                            || '/' || z_asgard.asgard_role_trans_acl(quote_ident(c_roles.producteur)::regrole))
        THEN
            RAISE NOTICE 'acl_idi = %', acl_idi ;
            RAISE NOTICE 'ECHEC dedi_c' ;
            r := False ;
        END IF ;
        
        IF variante.dlec_o IS NULL AND acl_idi ~ ('^(.+[,])?' || z_asgard.asgard_role_trans_acl(quote_ident(o_roles.lecteur)::regrole) || '[=]')
            OR variante.dlec_o IS NOT NULL AND NOT acl_idi ~ ('^(.+[,])?' || z_asgard.asgard_role_trans_acl(quote_ident(o_roles.lecteur)::regrole)
                            || '[=]' || variante.dlec_o
                            || '/' || z_asgard.asgard_role_trans_acl(quote_ident(c_roles.producteur)::regrole))
        THEN
            RAISE NOTICE 'acl_idi = %', acl_idi ;
            RAISE NOTICE 'ECHEC dlec_o' ;
            r := False ;
        END IF ;
        
        IF variante.dlec_c IS NULL AND acl_idi ~ ('^(.+[,])?' || z_asgard.asgard_role_trans_acl(quote_ident(c_roles.lecteur)::regrole) || '[=]')
            OR variante.dlec_c IS NOT NULL AND NOT acl_idi ~ ('^(.+[,])?' || z_asgard.asgard_role_trans_acl(quote_ident(c_roles.lecteur)::regrole)
                            || '[=]' || variante.dlec_c
                            || '/' || z_asgard.asgard_role_trans_acl(quote_ident(c_roles.producteur)::regrole))
        THEN
            RAISE NOTICE 'acl_idi = %', acl_idi ;
            RAISE NOTICE 'ECHEC dlec_c' ;
            r := False ;
        END IF ;
        
        IF variante.drec IS NULL AND acl_idi ~ ('^(.+[,])?' || z_asgard.asgard_role_trans_acl(quote_ident('g_asgard_rec')::regrole) || '[=]')
            OR variante.drec IS NOT NULL AND NOT acl_idi ~ ('^(.+[,])?' || z_asgard.asgard_role_trans_acl(quote_ident('g_asgard_rec')::regrole)
                            || '[=]' || variante.drec
                            || '/' || z_asgard.asgard_role_trans_acl(quote_ident(c_roles.producteur)::regrole))
        THEN
            RAISE NOTICE 'acl_idi = %', acl_idi ;
            RAISE NOTICE 'ECHEC drec' ;
            r := False ;
        END IF ;
        
        t := c ;
        c := o ;
        o := t ;
    
    END LOOP ;
    
    DROP SCHEMA c_bibliotheque CASCADE ;
    DROP SCHEMA c_librairie CASCADE ;
    DELETE FROM z_asgard.gestion_schema_usr ;
    
    DROP ROLE g_asgard_edi1 ;
    DROP ROLE g_asgard_edi2 ;
    DROP ROLE g_asgard_lec1 ;
    DROP ROLE g_asgard_lec2 ;
    DROP ROLE g_asgard_pro1 ;
    DROP ROLE g_asgard_pro2 ;
    DROP ROLE g_asgard_rec ;
    
    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                            e_detl = PG_EXCEPTION_DETAIL ;
    RAISE NOTICE '%', e_mssg
        USING DETAIL = e_detl ;
        
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t055() IS 'ASGARD recette. TEST : (asgard_deplace_obj) gestion des séquences associées.' ;


-- FUNCTION: z_asgard_recette.t055b()

CREATE OR REPLACE FUNCTION z_asgard_recette.t055b()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean := True ;
   variante record ;
   o_roles record ;
   c_roles record ;
   o text := 'c_Bibliothèque' ;
   c text := 'c_LIB rairie' ;
   t text ;
   e_mssg text ;
   e_detl text ;
   acl_idi text ;
   acl_ids text ;
BEGIN

    CREATE ROLE "g_asgard REC!!!" ;

    CREATE SCHEMA "c_Bibliothèque" ;
    UPDATE z_asgard.gestion_schema_usr
        SET producteur = 'g_asgard +pro1',
            editeur = 'g_asgard_EDI1',
            lecteur = 'g_asgard lec1'
        WHERE nom_schema = 'c_Bibliothèque' ;
    
    CREATE SCHEMA "c_LIB rairie" ;
    UPDATE z_asgard.gestion_schema_usr
        SET producteur = 'g_asgard--pro2',
            editeur = 'g_asgard_EDI2#',
            lecteur = 'g_asg@rd lec2'
        WHERE nom_schema = 'c_LIB rairie' ;
    
    IF current_setting('server_version_num')::int >= 100000
    THEN
        EXECUTE 'CREATE TABLE "c_Bibliothèque"."Journal du mur"("i*di" integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY, jour date, entree text)' ;
    ELSE
        CREATE TABLE "c_Bibliothèque"."Journal du mur"("i*di" serial PRIMARY KEY, jour date, entree text) ;
    END IF ;
    CREATE TABLE "c_Bibliothèque"."tours-de-garde"("IDS" serial PRIMARY KEY, jour date, nom text) ;
    
    ------ application des 6 variantes -------
    FOR variante IN (
            SELECT *
                FROM unnest(
                    ARRAY[1,            2,              3,              4,              5,              6], -- numéro de variante
                    ARRAY[NULL,         NULL,           NULL,           NULL,           NULL,           NULL], -- droits du producteur du schéma de départ
                    ARRAY['[rw]{2}',   '[rwU]{3}',     '[rw]{2}',       '[rw]{2}',      '[rw]{2}',      '[rwU]{3}'], -- droits du producteur du schéma d'arrivée
                    ARRAY[NULL,         NULL,           NULL,           '[rU]{2}',      NULL,           NULL], -- droits de l'éditeur du schéma de départ
                    ARRAY['[rU]{2}',   '[rU]{2}',       '[rU]{2}',      NULL,           '[rU]{2}',      '[rU]{2}'], -- droits de l'éditeur du schéma d'arrivée
                    ARRAY[NULL,         NULL,           NULL,           '[rU]{2}',      NULL,           NULL], -- droits du lecteur du schéma de départ
                    ARRAY['[rU]{2}',    'r',            '[rU]{2}',      NULL,           'r',            'r'], -- droits du lecteur du schéma d'arrivée
                    ARRAY['[rw]{2}',    NULL,           NULL,           '[rw]{2}',      NULL,           '[rw]{2}']  -- droits de "g_asgard REC!!!"
                    ) AS t (n, dpro_o, dpro_c, dedi_o, dedi_c, dlec_o, dlec_c, drec)
                ORDER BY n
            )
    LOOP
        RAISE NOTICE '-- variante % ----------------', variante.n::text ;
        PERFORM z_asgard.asgard_initialise_schema(o) ;
        
        SELECT producteur, editeur, lecteur
            INTO o_roles
            FROM z_asgard.gestion_schema_usr
            WHERE nom_schema = o ;
            
        SELECT producteur, editeur, lecteur
            INTO c_roles
            FROM z_asgard.gestion_schema_usr
            WHERE nom_schema = c ;
        
        EXECUTE 'GRANT SELECT, UPDATE ON SEQUENCE ' || quote_ident(o) || '.' || quote_ident('Journal du mur_i*di_seq') || ' TO ' || quote_ident('g_asgard REC!!!') ;
        EXECUTE 'GRANT SELECT, UPDATE ON SEQUENCE ' || quote_ident(o) || '.' || quote_ident('tours-de-garde_IDS_seq') || ' TO ' || quote_ident('g_asgard REC!!!') ;
        
        EXECUTE 'GRANT USAGE ON SEQUENCE ' || quote_ident(o) || '.' || quote_ident('Journal du mur_i*di_seq') || ' TO ' || quote_ident(o_roles.lecteur) ;
        EXECUTE 'GRANT USAGE ON SEQUENCE ' || quote_ident(o) || '.' || quote_ident('tours-de-garde_IDS_seq') || ' TO ' || quote_ident(o_roles.lecteur) ;
        
        EXECUTE 'REVOKE USAGE ON SEQUENCE ' || quote_ident(o) || '.' || quote_ident('Journal du mur_i*di_seq') || ' FROM ' || quote_ident(o_roles.producteur) ;
        EXECUTE 'REVOKE USAGE ON SEQUENCE ' || quote_ident(o) || '.' || quote_ident('tours-de-garde_IDS_seq') || ' FROM ' || quote_ident(o_roles.producteur) ;
        
        PERFORM z_asgard.asgard_deplace_obj(o, 'Journal du mur', 'table', c, variante.n) ;
        PERFORM z_asgard.asgard_deplace_obj(o, 'tours-de-garde', 'table', c, variante.n) ;
        
        
        SELECT array_to_string(relacl, ',')
            INTO STRICT acl_idi
            FROM pg_class
            WHERE relnamespace::regnamespace::text = quote_ident(c)
                AND relname = 'Journal du mur_i*di_seq' ;
        
        SELECT array_to_string(relacl, ',')
            INTO STRICT acl_ids
            FROM pg_class
            WHERE relnamespace::regnamespace::text = quote_ident(c)
                AND relname = 'tours-de-garde_IDS_seq' ;
  
        -- serial
        IF variante.dpro_o IS NULL AND acl_ids ~ ('^(.+[,])?' || z_asgard.asgard_role_trans_acl(quote_ident(o_roles.producteur)::regrole) || '[=]')
            OR variante.dpro_o IS NOT NULL AND NOT acl_ids ~ ('^' || z_asgard.asgard_role_trans_acl(quote_ident(o_roles.producteur)::regrole)
                            || '[=]' || variante.dpro_o
                            || '/' || z_asgard.asgard_role_trans_acl(quote_ident(c_roles.producteur)::regrole))
        THEN
            RAISE NOTICE 'acl_ids = %', acl_ids ;
            RAISE NOTICE 'ECHEC dpro_o' ;
            r := False ;
        END IF ;
        
        IF variante.dpro_c IS NULL AND acl_ids ~ ('^(.+[,])?' || z_asgard.asgard_role_trans_acl(quote_ident(c_roles.producteur)::regrole) || '[=]')
            OR variante.dpro_c IS NOT NULL AND NOT acl_ids ~ ('^(.+[,])?' || z_asgard.asgard_role_trans_acl(quote_ident(c_roles.producteur)::regrole)
                            || '[=]' || variante.dpro_c
                            || '/' || z_asgard.asgard_role_trans_acl(quote_ident(c_roles.producteur)::regrole))
        THEN
            RAISE NOTICE 'acl_ids = %', acl_ids ;
            RAISE NOTICE 'ECHEC dpro_c' ;
            r := False ;
        END IF ;
        
        IF variante.dedi_o IS NULL AND acl_ids ~ ('^(.+[,])?' || z_asgard.asgard_role_trans_acl(quote_ident(o_roles.editeur)::regrole) || '[=]')
            OR variante.dedi_o IS NOT NULL AND NOT acl_ids ~ ('^(.+[,])?' || z_asgard.asgard_role_trans_acl(quote_ident(o_roles.editeur)::regrole)
                            || '[=]' || variante.dedi_o
                            || '/' || z_asgard.asgard_role_trans_acl(quote_ident(c_roles.producteur)::regrole))
        THEN
            RAISE NOTICE 'acl_ids = %', acl_ids ;
            RAISE NOTICE 'ECHEC dedi_o' ;
            r := False ;
        END IF ;
        
        IF variante.dedi_c IS NULL AND acl_ids ~ ('^(.+[,])?' || z_asgard.asgard_role_trans_acl(quote_ident(c_roles.editeur)::regrole) || '[=]')
            OR variante.dedi_c IS NOT NULL AND NOT acl_ids ~ ('^(.+[,])?' || z_asgard.asgard_role_trans_acl(quote_ident(c_roles.editeur)::regrole)
                            || '[=]' || variante.dedi_c
                            || '/' || z_asgard.asgard_role_trans_acl(quote_ident(c_roles.producteur)::regrole))
        THEN
            RAISE NOTICE 'acl_ids = %', acl_ids ;
            RAISE NOTICE 'ECHEC dedi_c' ;
            r := False ;
        END IF ;
        
        IF variante.dlec_o IS NULL AND acl_ids ~ ('^(.+[,])?' || z_asgard.asgard_role_trans_acl(quote_ident(o_roles.lecteur)::regrole) || '[=]')
            OR variante.dlec_o IS NOT NULL AND NOT acl_ids ~ ('^(.+[,])?' || z_asgard.asgard_role_trans_acl(quote_ident(o_roles.lecteur)::regrole)
                            || '[=]' || variante.dlec_o
                            || '/' || z_asgard.asgard_role_trans_acl(quote_ident(c_roles.producteur)::regrole))
        THEN
            RAISE NOTICE 'acl_ids = %', acl_ids ;
            RAISE NOTICE 'ECHEC dlec_o' ;
            r := False ;
        END IF ;
        
        IF variante.dlec_c IS NULL AND acl_ids ~ ('^(.+[,])?' || z_asgard.asgard_role_trans_acl(quote_ident(c_roles.lecteur)::regrole) || '[=]')
            OR variante.dlec_c IS NOT NULL AND NOT acl_ids ~ ('^(.+[,])?' || z_asgard.asgard_role_trans_acl(quote_ident(c_roles.lecteur)::regrole)
                            || '[=]' || variante.dlec_c
                            || '/' || z_asgard.asgard_role_trans_acl(quote_ident(c_roles.producteur)::regrole))
        THEN
            RAISE NOTICE 'acl_ids = %', acl_ids ;
            RAISE NOTICE 'ECHEC dlec_c' ;
            r := False ;
        END IF ;
        
        IF variante.drec IS NULL AND acl_ids ~ ('^(.+[,])?' || z_asgard.asgard_role_trans_acl(quote_ident('g_asgard REC!!!')::regrole) || '[=]')
            OR variante.drec IS NOT NULL AND NOT acl_ids ~ ('^(.+[,])?' || z_asgard.asgard_role_trans_acl(quote_ident('g_asgard REC!!!')::regrole)
                            || '[=]' || variante.drec
                            || '/' || z_asgard.asgard_role_trans_acl(quote_ident(c_roles.producteur)::regrole))
        THEN
            RAISE NOTICE 'acl_ids = %', acl_ids ;
            RAISE NOTICE 'ECHEC drec' ;
            r := False ;
        END IF ;
        
        
        -- identity
        IF variante.dpro_o IS NULL AND acl_idi ~ ('^(.+[,])?' || z_asgard.asgard_role_trans_acl(quote_ident(o_roles.producteur)::regrole) || '[=]')
            OR variante.dpro_o IS NOT NULL AND NOT acl_idi ~ ('^' || z_asgard.asgard_role_trans_acl(quote_ident(o_roles.producteur)::regrole)
                            || '[=]' || variante.dpro_o
                            || '/' || z_asgard.asgard_role_trans_acl(quote_ident(c_roles.producteur)::regrole))
        THEN
            RAISE NOTICE 'acl_idi = %', acl_idi ;
            RAISE NOTICE 'ECHEC dpro_o' ;
            r := False ;
        END IF ;
        
        IF variante.dpro_c IS NULL AND acl_idi ~ ('^(.+[,])?' || z_asgard.asgard_role_trans_acl(quote_ident(c_roles.producteur)::regrole) || '[=]')
            OR variante.dpro_c IS NOT NULL AND NOT acl_idi ~ ('^(.+[,])?' || z_asgard.asgard_role_trans_acl(quote_ident(c_roles.producteur)::regrole)
                            || '[=]' || variante.dpro_c
                            || '/' || z_asgard.asgard_role_trans_acl(quote_ident(c_roles.producteur)::regrole))
        THEN
            RAISE NOTICE 'acl_idi = %', acl_idi ;
            RAISE NOTICE 'ECHEC dpro_c' ;
            r := False ;
        END IF ;
        
        IF variante.dedi_o IS NULL AND acl_idi ~ ('^(.+[,])?' || z_asgard.asgard_role_trans_acl(quote_ident(o_roles.editeur)::regrole) || '[=]')
            OR variante.dedi_o IS NOT NULL AND NOT acl_idi ~ ('^(.+[,])?' || z_asgard.asgard_role_trans_acl(quote_ident(o_roles.editeur)::regrole)
                            || '[=]' || variante.dedi_o
                            || '/' || z_asgard.asgard_role_trans_acl(quote_ident(c_roles.producteur)::regrole))
        THEN
            RAISE NOTICE 'acl_idi = %', acl_idi ;
            RAISE NOTICE 'ECHEC dedi_o' ;
            r := False ;
        END IF ;
        
        IF variante.dedi_c IS NULL AND acl_idi ~ ('^(.+[,])?' || z_asgard.asgard_role_trans_acl(quote_ident(c_roles.editeur)::regrole) || '[=]')
            OR variante.dedi_c IS NOT NULL AND NOT acl_idi ~ ('^(.+[,])?' || z_asgard.asgard_role_trans_acl(quote_ident(c_roles.editeur)::regrole)
                            || '[=]' || variante.dedi_c
                            || '/' || z_asgard.asgard_role_trans_acl(quote_ident(c_roles.producteur)::regrole))
        THEN
            RAISE NOTICE 'acl_idi = %', acl_idi ;
            RAISE NOTICE 'ECHEC dedi_c' ;
            r := False ;
        END IF ;
        
        IF variante.dlec_o IS NULL AND acl_idi ~ ('^(.+[,])?' || z_asgard.asgard_role_trans_acl(quote_ident(o_roles.lecteur)::regrole) || '[=]')
            OR variante.dlec_o IS NOT NULL AND NOT acl_idi ~ ('^(.+[,])?' || z_asgard.asgard_role_trans_acl(quote_ident(o_roles.lecteur)::regrole)
                            || '[=]' || variante.dlec_o
                            || '/' || z_asgard.asgard_role_trans_acl(quote_ident(c_roles.producteur)::regrole))
        THEN
            RAISE NOTICE 'acl_idi = %', acl_idi ;
            RAISE NOTICE 'ECHEC dlec_o' ;
            r := False ;
        END IF ;
        
        IF variante.dlec_c IS NULL AND acl_idi ~ ('^(.+[,])?' || z_asgard.asgard_role_trans_acl(quote_ident(c_roles.lecteur)::regrole) || '[=]')
            OR variante.dlec_c IS NOT NULL AND NOT acl_idi ~ ('^(.+[,])?' || z_asgard.asgard_role_trans_acl(quote_ident(c_roles.lecteur)::regrole)
                            || '[=]' || variante.dlec_c
                            || '/' || z_asgard.asgard_role_trans_acl(quote_ident(c_roles.producteur)::regrole))
        THEN
            RAISE NOTICE 'acl_idi = %', acl_idi ;
            RAISE NOTICE 'ECHEC dlec_c' ;
            r := False ;
        END IF ;
        
        IF variante.drec IS NULL AND acl_idi ~ ('^(.+[,])?' || z_asgard.asgard_role_trans_acl(quote_ident('g_asgard REC!!!')::regrole) || '[=]')
            OR variante.drec IS NOT NULL AND NOT acl_idi ~ ('^(.+[,])?' || z_asgard.asgard_role_trans_acl(quote_ident('g_asgard REC!!!')::regrole)
                            || '[=]' || variante.drec
                            || '/' || z_asgard.asgard_role_trans_acl(quote_ident(c_roles.producteur)::regrole))
        THEN
            RAISE NOTICE 'acl_idi = %', acl_idi ;
            RAISE NOTICE 'ECHEC drec' ;
            r := False ;
        END IF ;
        
        t := c ;
        c := o ;
        o := t ;
    
    END LOOP ;
    
    DROP SCHEMA "c_Bibliothèque" CASCADE ;
    DROP SCHEMA "c_LIB rairie" CASCADE ;
    DELETE FROM z_asgard.gestion_schema_usr ;
    
    DROP ROLE "g_asgard_EDI1" ;
    DROP ROLE "g_asgard_EDI2#" ;
    DROP ROLE "g_asgard lec1" ;
    DROP ROLE "g_asg@rd lec2" ;
    DROP ROLE "g_asgard +pro1" ;
    DROP ROLE "g_asgard--pro2" ;
    DROP ROLE "g_asgard REC!!!" ;
    
    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                            e_detl = PG_EXCEPTION_DETAIL ;
    RAISE NOTICE '%', e_mssg
        USING DETAIL = e_detl ;
        
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t055b() IS 'ASGARD recette. TEST : (asgard_deplace_obj) gestion des séquences associées.' ;


-- FUNCTION: z_asgard_recette.t056()

CREATE OR REPLACE FUNCTION z_asgard_recette.t056()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
   o_role oid ;
   o_nsp oid ;
   e_mssg text ;
   e_detl text ;
BEGIN

    CREATE ROLE g_asgard_rec ;
    CREATE ROLE g_asgard_rec_bis ;
    o_role = 'g_asgard_rec'::regrole::oid ;
    
    CREATE SCHEMA c_bibliotheque AUTHORIZATION g_asgard_rec ;
    o_nsp = 'c_bibliotheque'::regnamespace::oid ;
    
    ------ synchronisation à la création ------
    
    -- #1
    IF current_setting('server_version_num')::int >= 100000
    THEN
        CREATE COLLATION c_bibliotheque.biblicoll (provider = icu, locale = 'fr@colNumeric=yes') ;
    ELSE
        CREATE COLLATION c_bibliotheque.biblicoll FROM pg_catalog.default ;
    END IF ;
    
    SELECT count(*) = 1
        INTO STRICT b
        FROM pg_collation
        WHERE collnamespace = o_nsp AND collowner = o_role ;
        
    r := b ;
    RAISE NOTICE '56-1 > %', r::text ;
    
    -- #2
    CREATE CONVERSION c_bibliotheque.biblicon FOR 'WIN' TO 'UTF8' FROM win_to_utf8 ;
    
    SELECT count(*) = 1
        INTO STRICT b
        FROM pg_conversion
        WHERE connamespace = o_nsp AND conowner = o_role ;
        
    r := r AND b ;
    RAISE NOTICE '56-2 > %', r::text ;
    
    -- #3
    CREATE FUNCTION c_bibliotheque.normalise(text)
        RETURNS text
        AS $$ SELECT regexp_replace(translate(lower($1), 'àâéèêëîïöôüûùç', 'aaeeeeiioouuuc'), '[^a-z0-9_]', '_', 'g') $$
        LANGUAGE SQL ;    
    CREATE OPERATOR c_bibliotheque.@ (PROCEDURE = c_bibliotheque.normalise(text), RIGHTARG = text) ;
    
    SELECT count(*) = 1
        INTO STRICT b
        FROM pg_operator
        WHERE oprnamespace = o_nsp AND oprowner = o_role ;
        
    r := r AND b ;
    RAISE NOTICE '56-3 > %', r::text ;
    
    -- #4
    CREATE TEXT SEARCH CONFIGURATION c_bibliotheque.recherche_config (COPY = french) ;
    
    SELECT count(*) = 1
        INTO STRICT b
        FROM pg_ts_config
        WHERE cfgnamespace = o_nsp AND cfgowner = o_role ;
        
    r := r AND b ;
    RAISE NOTICE '56-4 > %', r::text ;
    
    -- #5
    CREATE TEXT SEARCH DICTIONARY c_bibliotheque.recherche_dico (TEMPLATE = snowball, LANGUAGE = french) ;
    
    SELECT count(*) = 1
        INTO STRICT b
        FROM pg_ts_dict
        WHERE dictnamespace = o_nsp AND dictowner = o_role ;
        
    r := r AND b ;
    RAISE NOTICE '56-5 > %', r::text ;
    
    -- #6
    SELECT count(*) = 0
        INTO STRICT b
        FROM z_asgard_admin.asgard_diagnostic() ;
        
    r := r AND b ;
    RAISE NOTICE '56-6 > %', r::text ;
    
    ------ ré-synchronisation auto en cas de modification ------
    
    -- #7
    ALTER COLLATION c_bibliotheque.biblicoll OWNER TO g_asgard_rec_bis ;
    
    SELECT count(*) = 1
        INTO STRICT b
        FROM pg_collation
        WHERE collnamespace = o_nsp AND collowner = o_role ;
        
    r := b ;
    RAISE NOTICE '56-7 > %', r::text ;
    
    -- #8
    ALTER CONVERSION c_bibliotheque.biblicon OWNER TO g_asgard_rec_bis ;
    
    SELECT count(*) = 1
        INTO STRICT b
        FROM pg_conversion
        WHERE connamespace = o_nsp AND conowner = o_role ;
        
    r := r AND b ;
    RAISE NOTICE '56-8 > %', r::text ;
    
    -- #9
    ALTER OPERATOR c_bibliotheque.@ (NONE, text) OWNER TO g_asgard_rec_bis ;
    
    SELECT count(*) = 1
        INTO STRICT b
        FROM pg_operator
        WHERE oprnamespace = o_nsp AND oprowner = o_role ;
        
    r := r AND b ;
    RAISE NOTICE '56-9 > %', r::text ;
    
    -- #10
    ALTER TEXT SEARCH CONFIGURATION c_bibliotheque.recherche_config OWNER TO g_asgard_rec_bis ;
    
    SELECT count(*) = 1
        INTO STRICT b
        FROM pg_ts_config
        WHERE cfgnamespace = o_nsp AND cfgowner = o_role ;
        
    r := r AND b ;
    RAISE NOTICE '56-10 > %', r::text ;
    
    -- #11
    ALTER TEXT SEARCH DICTIONARY c_bibliotheque.recherche_dico OWNER TO g_asgard_rec_bis ;
    
    SELECT count(*) = 1
        INTO STRICT b
        FROM pg_ts_dict
        WHERE dictnamespace = o_nsp AND dictowner = o_role ;
        
    r := r AND b ;
    RAISE NOTICE '56-11 > %', r::text ;
    
    -- #12
    SELECT count(*) = 0
        INTO STRICT b
        FROM z_asgard_admin.asgard_diagnostic() ;
        
    r := r AND b ;
    RAISE NOTICE '56-12 > %', r::text ;
   
    
    ------ synchronisation avec asgard_initialise_schema ------
    ALTER EVENT TRIGGER asgard_on_alter_objet DISABLE ;
    
    ALTER COLLATION c_bibliotheque.biblicoll OWNER TO g_asgard_rec_bis ;
    ALTER CONVERSION c_bibliotheque.biblicon OWNER TO g_asgard_rec_bis ;
    ALTER OPERATOR c_bibliotheque.@ (NONE, text) OWNER TO g_asgard_rec_bis ;
    ALTER TEXT SEARCH CONFIGURATION c_bibliotheque.recherche_config OWNER TO g_asgard_rec_bis ;
    ALTER TEXT SEARCH DICTIONARY c_bibliotheque.recherche_dico OWNER TO g_asgard_rec_bis ;
    
    ALTER EVENT TRIGGER asgard_on_alter_objet ENABLE ;
    
    -- #13
    SELECT count(*) = 5
        INTO STRICT b
        FROM z_asgard_admin.asgard_diagnostic() ;
        
    r := r AND b ;
    RAISE NOTICE '56-13 > %', r::text ;
    
    PERFORM z_asgard.asgard_initialise_schema('c_bibliotheque') ;
    
    -- #14
    SELECT count(*) = 0
        INTO STRICT b
        FROM z_asgard_admin.asgard_diagnostic() ;
        
    r := r AND b ;
    RAISE NOTICE '56-14 > %', r::text ;
    
    ------ modification du propriétaire du schéma par un ALTER SCHEMA ------
    ALTER SCHEMA c_bibliotheque OWNER TO g_asgard_rec_bis ;
    
    -- #15
    SELECT count(*) = 0
        INTO STRICT b
        FROM z_asgard_admin.asgard_diagnostic() ;
        
    r := r AND b ;
    RAISE NOTICE '56-15 > %', r::text ;
    
    ------ modification du producteur du schéma par un UPDATE ------
    UPDATE z_asgard.gestion_schema_usr
        SET producteur = 'g_asgard_rec'
        WHERE nom_schema = 'c_bibliotheque' ;
    
    -- #16
    SELECT count(*) = 0
        INTO STRICT b
        FROM z_asgard_admin.asgard_diagnostic() ;
        
    r := r AND b ;
    RAISE NOTICE '56-16 > %', r::text ;


    DROP SCHEMA c_bibliotheque CASCADE ;
    DELETE FROM z_asgard.gestion_schema_usr ;
    
    DROP ROLE g_asgard_rec ;
    DROP ROLE g_asgard_rec_bis ;
    
    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                            e_detl = PG_EXCEPTION_DETAIL ;
    RAISE NOTICE '%', e_mssg
        USING DETAIL = e_detl ;
        
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t056() IS 'ASGARD recette. TEST : synchronisation des propriétaires des objets sans ACL.' ;


-- FUNCTION: z_asgard_recette.t056b()

CREATE OR REPLACE FUNCTION z_asgard_recette.t056b()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
   o_role oid ;
   o_nsp oid ;
   e_mssg text ;
   e_detl text ;
BEGIN

    CREATE ROLE "g_asgard_REC" ;
    CREATE ROLE "g_asgard REC*" ;
    o_role = '"g_asgard_REC"'::regrole::oid ;
    
    CREATE SCHEMA "c_Bibliothèque" AUTHORIZATION "g_asgard_REC" ;
    o_nsp = '"c_Bibliothèque"'::regnamespace::oid ;
    
    ------ synchronisation à la création ------
    
    -- #1
    IF current_setting('server_version_num')::int >= 100000
    THEN
        CREATE COLLATION "c_Bibliothèque"."BIBLIcoll" (provider = icu, locale = 'fr@colNumeric=yes') ;
    ELSE
        CREATE COLLATION "c_Bibliothèque"."BIBLIcoll" FROM pg_catalog.default ;
    END IF ;
    
    SELECT count(*) = 1
        INTO STRICT b
        FROM pg_collation
        WHERE collnamespace = o_nsp AND collowner = o_role ;
        
    r := b ;
    RAISE NOTICE '56b-1 > %', r::text ;
    
    -- #2
    CREATE CONVERSION "c_Bibliothèque"."BIBLI CO^N" FOR 'WIN' TO 'UTF8' FROM win_to_utf8 ;
    
    SELECT count(*) = 1
        INTO STRICT b
        FROM pg_conversion
        WHERE connamespace = o_nsp AND conowner = o_role ;
        
    r := r AND b ;
    RAISE NOTICE '56b-2 > %', r::text ;
    
    -- #3
    CREATE FUNCTION "c_Bibliothèque".normalise(text)
        RETURNS text
        AS $$ SELECT regexp_replace(translate(lower($1), 'àâéèêëîïöôüûùç', 'aaeeeeiioouuuc'), '[^a-z0-9_]', '_', 'g') $$
        LANGUAGE SQL ;    
    CREATE OPERATOR "c_Bibliothèque".@ (PROCEDURE = "c_Bibliothèque".normalise(text), RIGHTARG = text) ;
    
    SELECT count(*) = 1
        INTO STRICT b
        FROM pg_operator
        WHERE oprnamespace = o_nsp AND oprowner = o_role ;
        
    r := r AND b ;
    RAISE NOTICE '56b-3 > %', r::text ;
    
    -- #4
    CREATE TEXT SEARCH CONFIGURATION "c_Bibliothèque"."? config" (COPY = french) ;
    
    SELECT count(*) = 1
        INTO STRICT b
        FROM pg_ts_config
        WHERE cfgnamespace = o_nsp AND cfgowner = o_role ;
        
    r := r AND b ;
    RAISE NOTICE '56b-4 > %', r::text ;
    
    -- #5
    CREATE TEXT SEARCH DICTIONARY "c_Bibliothèque"."? dico" (TEMPLATE = snowball, LANGUAGE = french) ;
    
    SELECT count(*) = 1
        INTO STRICT b
        FROM pg_ts_dict
        WHERE dictnamespace = o_nsp AND dictowner = o_role ;
        
    r := r AND b ;
    RAISE NOTICE '56b-5 > %', r::text ;
    
    -- #6
    SELECT count(*) = 0
        INTO STRICT b
        FROM z_asgard_admin.asgard_diagnostic() ;
        
    r := r AND b ;
    RAISE NOTICE '56b-6 > %', r::text ;
    
    ------ ré-synchronisation auto en cas de modification ------
    
    -- #7
    ALTER COLLATION "c_Bibliothèque"."BIBLIcoll" OWNER TO "g_asgard REC*" ;
    
    SELECT count(*) = 1
        INTO STRICT b
        FROM pg_collation
        WHERE collnamespace = o_nsp AND collowner = o_role ;
        
    r := b ;
    RAISE NOTICE '56b-7 > %', r::text ;
    
    -- #8
    ALTER CONVERSION "c_Bibliothèque"."BIBLI CO^N" OWNER TO "g_asgard REC*" ;
    
    SELECT count(*) = 1
        INTO STRICT b
        FROM pg_conversion
        WHERE connamespace = o_nsp AND conowner = o_role ;
        
    r := r AND b ;
    RAISE NOTICE '56b-8 > %', r::text ;
    
    -- #9
    ALTER OPERATOR "c_Bibliothèque".@ (NONE, text) OWNER TO "g_asgard REC*" ;
    
    SELECT count(*) = 1
        INTO STRICT b
        FROM pg_operator
        WHERE oprnamespace = o_nsp AND oprowner = o_role ;
        
    r := r AND b ;
    RAISE NOTICE '56b-9 > %', r::text ;
    
    -- #10
    ALTER TEXT SEARCH CONFIGURATION "c_Bibliothèque"."? config" OWNER TO "g_asgard REC*" ;
    
    SELECT count(*) = 1
        INTO STRICT b
        FROM pg_ts_config
        WHERE cfgnamespace = o_nsp AND cfgowner = o_role ;
        
    r := r AND b ;
    RAISE NOTICE '56b-10 > %', r::text ;
    
    -- #11
    ALTER TEXT SEARCH DICTIONARY "c_Bibliothèque"."? dico" OWNER TO "g_asgard REC*" ;
    
    SELECT count(*) = 1
        INTO STRICT b
        FROM pg_ts_dict
        WHERE dictnamespace = o_nsp AND dictowner = o_role ;
        
    r := r AND b ;
    RAISE NOTICE '56b-11 > %', r::text ;
    
    -- #12
    SELECT count(*) = 0
        INTO STRICT b
        FROM z_asgard_admin.asgard_diagnostic() ;
        
    r := r AND b ;
    RAISE NOTICE '56b-12 > %', r::text ;
   
    
    ------ synchronisation avec asgard_initialise_schema ------
    ALTER EVENT TRIGGER asgard_on_alter_objet DISABLE ;
    
    ALTER COLLATION "c_Bibliothèque"."BIBLIcoll" OWNER TO "g_asgard REC*" ;
    ALTER CONVERSION "c_Bibliothèque"."BIBLI CO^N" OWNER TO "g_asgard REC*" ;
    ALTER OPERATOR "c_Bibliothèque".@ (NONE, text) OWNER TO "g_asgard REC*" ;
    ALTER TEXT SEARCH CONFIGURATION "c_Bibliothèque"."? config" OWNER TO "g_asgard REC*" ;
    ALTER TEXT SEARCH DICTIONARY "c_Bibliothèque"."? dico" OWNER TO "g_asgard REC*" ;
    
    ALTER EVENT TRIGGER asgard_on_alter_objet ENABLE ;
    
    -- #13
    SELECT count(*) = 5
        INTO STRICT b
        FROM z_asgard_admin.asgard_diagnostic() ;
        
    r := r AND b ;
    RAISE NOTICE '56b-13 > %', r::text ;
    
    PERFORM z_asgard.asgard_initialise_schema('c_Bibliothèque') ;
    
    -- #14
    SELECT count(*) = 0
        INTO STRICT b
        FROM z_asgard_admin.asgard_diagnostic() ;
        
    r := r AND b ;
    RAISE NOTICE '56b-14 > %', r::text ;
    
    ------ modification du propriétaire du schéma par un ALTER SCHEMA ------
    ALTER SCHEMA "c_Bibliothèque" OWNER TO "g_asgard REC*" ;
    
    -- #15
    SELECT count(*) = 0
        INTO STRICT b
        FROM z_asgard_admin.asgard_diagnostic() ;
        
    r := r AND b ;
    RAISE NOTICE '56-15 > %', r::text ;
    
    ------ modification du producteur du schéma par un UPDATE ------
    UPDATE z_asgard.gestion_schema_usr
        SET producteur = 'g_asgard_REC'
        WHERE nom_schema = 'c_Bibliothèque' ;
    
    -- #16
    SELECT count(*) = 0
        INTO STRICT b
        FROM z_asgard_admin.asgard_diagnostic() ;
        
    r := r AND b ;
    RAISE NOTICE '56-16 > %', r::text ;


    DROP SCHEMA "c_Bibliothèque" CASCADE ;
    DELETE FROM z_asgard.gestion_schema_usr ;
    
    DROP ROLE "g_asgard_REC" ;
    DROP ROLE "g_asgard REC*" ;
    
    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                            e_detl = PG_EXCEPTION_DETAIL ;
    RAISE NOTICE '%', e_mssg
        USING DETAIL = e_detl ;
        
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t056b() IS 'ASGARD recette. TEST : synchronisation des propriétaires des objets sans ACL.' ;


-- FUNCTION: z_asgard_recette.t057()

CREATE OR REPLACE FUNCTION z_asgard_recette.t057()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
   e_mssg text ;
   e_detl text ;
BEGIN

    CREATE ROLE g_asgard_rec ;
    CREATE ROLE g_asgard_rec_bis ;

    CREATE SCHEMA c_bibliotheque ;
    CREATE SCHEMA c_librairie ;
    CREATE SCHEMA c_archives AUTHORIZATION g_asgard_rec ;
    CREATE SCHEMA c_laboratoire ;
     
    UPDATE z_asgard.gestion_schema_usr
        SET editeur = 'g_asgard_rec'
        WHERE nom_schema = 'c_librairie' ;
    
    PERFORM z_asgard_admin.asgard_sortie_gestion_schema('c_laboratoire') ;
    
    CREATE DOMAIN c_bibliotheque.chiffre_pair int
        CONSTRAINT chiffre_pair_check CHECK (VALUE > 0 AND VALUE % 2 = 0) ;
    GRANT USAGE ON TYPE c_bibliotheque.chiffre_pair TO g_asgard_rec ; 
    
    IF current_setting('server_version_num')::int >= 100000
    THEN
        EXECUTE 'CREATE TABLE c_librairie.journal_du_mur
            (id int PRIMARY KEY GENERATED ALWAYS AS IDENTITY, jour date, entree text, auteur text)' ;
    ELSE
        CREATE TABLE c_librairie.journal_du_mur
            (id serial PRIMARY KEY, jour date, entree text, auteur text) ;
    END IF ;
    REVOKE USAGE ON SEQUENCE c_librairie.journal_du_mur_id_seq FROM g_asgard_rec ;

    CREATE FUNCTION c_archives.normalise(text)
        RETURNS text
        AS $$ SELECT regexp_replace(translate(lower($1), 'àâéèêëîïöôüûùç', 'aaeeeeiioouuuc'), '[^a-z0-9_]', '_', 'g') $$
        LANGUAGE SQL ;
        
    CREATE OPERATOR c_laboratoire.@ (PROCEDURE = c_archives.normalise(text), RIGHTARG = text) ;
    ALTER OPERATOR c_laboratoire.@ (NONE, text) OWNER TO g_asgard_rec ;
    
    EXECUTE 'GRANT CREATE ON DATABASE ' || quote_ident(current_database()) || ' TO g_asgard_rec' ;

    ------ état des lieux ------
    
    -- #1
    SELECT count(*) = 1
        INTO STRICT b
        FROM z_asgard_admin.asgard_diagnostic(ARRAY['c_bibliotheque'])
        WHERE nom_schema = 'c_bibliotheque' ;
    
    r := b ;
    RAISE NOTICE '57-1 > %', r::text ;
        
    -- #2
    SELECT count(*) = 1
        INTO STRICT b
        FROM z_asgard_admin.asgard_diagnostic(ARRAY['c_librairie'])
        WHERE nom_schema = 'c_librairie' ;
    
    r := r AND b ;
    RAISE NOTICE '57-2 > %', r::text ;
    
    -- #3
    SELECT count(*) = 0
        INTO STRICT b
        FROM z_asgard_admin.asgard_diagnostic(ARRAY['c_archives'])
        WHERE nom_schema = 'c_archives' ;
    
    r := r AND b ;
    RAISE NOTICE '57-3 > %', r::text ;
    

    ------ réaffectation ------
    SELECT z_asgard_admin.asgard_reaffecte_role('g_asgard_rec', 'g_asgard_rec_bis', b_hors_asgard := True) IS NULL
        INTO STRICT b ;
        
    r := r AND b ;
    RAISE NOTICE '57-4 > %', r::text ;
    
    DROP ROLE g_asgard_rec ;
    
    -- #4
    SELECT count(*) = 1
        INTO STRICT b
        FROM z_asgard.gestion_schema_usr
        WHERE nom_schema = 'c_librairie'
            AND editeur = 'g_asgard_rec_bis' ;
            
    r := r AND b ;
    RAISE NOTICE '57-4b > %', r::text ;
    
    -- #5
    SELECT count(*) = 1
        INTO STRICT b
        FROM z_asgard_admin.asgard_diagnostic(ARRAY['c_librairie'])
        WHERE nom_schema = 'c_librairie' ;
    
    r := r AND b ;
    RAISE NOTICE '57-5 > %', r::text ;
    
    -- #6
    SELECT count(*) = 1
        INTO STRICT b
        FROM z_asgard_admin.asgard_diagnostic(ARRAY['c_bibliotheque'])
        WHERE nom_schema = 'c_bibliotheque' ;
    
    r := r AND b ;
    RAISE NOTICE '57-6 > %', r::text ;
    
    -- #7
    SELECT count(*) = 1
        INTO STRICT b
        FROM z_asgard.gestion_schema_usr
        WHERE nom_schema = 'c_archives'
            AND producteur = 'g_asgard_rec_bis' ;
    
    r := r AND b ;
    RAISE NOTICE '57-7 > %', r::text ;
    
    -- #8
    SELECT count(*) = 0
        INTO STRICT b
        FROM z_asgard_admin.asgard_diagnostic(ARRAY['c_archives'])
        WHERE nom_schema = 'c_archives' ;
    
    r := r AND b ;
    RAISE NOTICE '57-8 > %', r::text ;
    
    -- #9
    SELECT count(*) = 1
        INTO STRICT b
        FROM pg_operator
        WHERE oprnamespace = quote_ident('c_laboratoire')::regnamespace::oid
            AND oprowner = quote_ident('g_asgard_rec_bis')::regrole::oid ;
    
    r := r AND b ;
    RAISE NOTICE '57-9 > %', r::text ;
    
    -- #10
    IF NOT has_database_privilege('g_asgard_rec_bis', current_database()::text, 'CREATE')
    THEN
        r := False ;
        RAISE NOTICE '57-10 > %', r::text ;
    END IF ;
    
    ------ suppression ------
    SELECT z_asgard_admin.asgard_reaffecte_role('g_asgard_rec_bis', b_hors_asgard := True) IS NULL
        INTO STRICT b ;
        
    r := r AND b ;
    RAISE NOTICE '57-11 > %', r::text ;
    
    DROP ROLE g_asgard_rec_bis ;
    
    -- #11
    SELECT count(*) = 1
        INTO STRICT b
        FROM z_asgard.gestion_schema_usr
        WHERE nom_schema = 'c_archives'
            AND producteur = 'g_admin' ;
    
    r := r AND b ;
    RAISE NOTICE '57-11b > %', r::text ;
    
    -- #12
    SELECT count(*) = 1
        INTO STRICT b
        FROM z_asgard.gestion_schema_usr
        WHERE nom_schema = 'c_librairie'
            AND editeur IS NULL ;
            
    r := r AND b ;
    RAISE NOTICE '57-12 > %', r::text ;
    
    -- #13
    SELECT count(*) = 0
        INTO STRICT b
        FROM z_asgard_admin.asgard_diagnostic() ;
    
    r := r AND b ;
    RAISE NOTICE '57-13 > %', r::text ;
    
    -- #14
    SELECT count(*) = 1
        INTO STRICT b
        FROM pg_operator
        WHERE oprnamespace = quote_ident('c_laboratoire')::regnamespace::oid
            AND oprowner = quote_ident('g_admin')::regrole::oid ;
    
    r := r AND b ;
    RAISE NOTICE '57-14 > %', r::text ;
    
    DROP SCHEMA c_bibliotheque CASCADE ;
    DROP SCHEMA c_librairie CASCADE ;
    DROP SCHEMA c_laboratoire CASCADE ;
    DROP SCHEMA c_archives CASCADE ;
    DELETE FROM z_asgard.gestion_schema_usr ;

    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                            e_detl = PG_EXCEPTION_DETAIL ;
    RAISE NOTICE '%', e_mssg
        USING DETAIL = e_detl ;
        
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t057() IS 'ASGARD recette. TEST : (asgard_reaffecte_role) transmission/suppression des droits (hors privilèges par défaut).' ;



-- FUNCTION: z_asgard_recette.t057b()

CREATE OR REPLACE FUNCTION z_asgard_recette.t057b()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
   e_mssg text ;
   e_detl text ;
BEGIN

    CREATE ROLE "g_asgard_REC" ;
    CREATE ROLE "g_asgard REC*" ;

    CREATE SCHEMA "c_Bibliothèque" ;
    CREATE SCHEMA "c_LIB air Ie" ;
    CREATE SCHEMA "c_Archives" AUTHORIZATION "g_asgard_REC" ;
    CREATE SCHEMA "c_LABO{rat}oire" ;
     
    UPDATE z_asgard.gestion_schema_usr
        SET editeur = 'g_asgard_REC'
        WHERE nom_schema = 'c_LIB air Ie' ;
    
    PERFORM z_asgard_admin.asgard_sortie_gestion_schema('c_LABO{rat}oire') ;
    
    CREATE DOMAIN "c_Bibliothèque"."Chiffre /2" int
        CONSTRAINT "Chiffre /2_check" CHECK (VALUE > 0 AND VALUE % 2 = 0) ;
    GRANT USAGE ON TYPE "c_Bibliothèque"."Chiffre /2" TO "g_asgard_REC" ; 
    
    IF current_setting('server_version_num')::int >= 100000
    THEN
        EXECUTE 'CREATE TABLE "c_LIB air Ie"."Journal du Mur§"
            (id int PRIMARY KEY GENERATED ALWAYS AS IDENTITY, jour date, entree text, auteur text)' ;
    ELSE
        CREATE TABLE "c_LIB air Ie"."Journal du Mur§"
            (id serial PRIMARY KEY, jour date, entree text, auteur text) ;
    END IF ;
    REVOKE USAGE ON SEQUENCE "c_LIB air Ie"."Journal du Mur§_id_seq" FROM "g_asgard_REC" ;

    CREATE FUNCTION "c_Archives"."norm-alise"(text)
        RETURNS text
        AS $$ SELECT regexp_replace(translate(lower($1), 'àâéèêëîïöôüûùç', 'aaeeeeiioouuuc'), '[^a-z0-9_]', '_', 'g') $$
        LANGUAGE SQL ;
        
    CREATE OPERATOR "c_LABO{rat}oire".@ (PROCEDURE = "c_Archives"."norm-alise"(text), RIGHTARG = text) ;
    ALTER OPERATOR "c_LABO{rat}oire".@ (NONE, text) OWNER TO "g_asgard_REC" ;
    
    EXECUTE 'GRANT CREATE ON DATABASE ' || quote_ident(current_database()) || ' TO "g_asgard_REC"' ;

    ------ état des lieux ------
    
    -- #1
    SELECT count(*) = 1
        INTO STRICT b
        FROM z_asgard_admin.asgard_diagnostic(ARRAY['c_Bibliothèque'])
        WHERE nom_schema = 'c_Bibliothèque' ;
    
    r := b ;
    RAISE NOTICE '57b-1 > %', r::text ;
        
    -- #2
    SELECT count(*) = 1
        INTO STRICT b
        FROM z_asgard_admin.asgard_diagnostic(ARRAY['c_LIB air Ie'])
        WHERE nom_schema = 'c_LIB air Ie' ;
    
    r := r AND b ;
    RAISE NOTICE '57b-2 > %', r::text ;
    
    -- #3
    SELECT count(*) = 0
        INTO STRICT b
        FROM z_asgard_admin.asgard_diagnostic(ARRAY['c_Archives'])
        WHERE nom_schema = 'c_Archives' ;
    
    r := r AND b ;
    RAISE NOTICE '57b-3 > %', r::text ;
    

    ------ réaffectation ------
    SELECT z_asgard_admin.asgard_reaffecte_role('g_asgard_REC', 'g_asgard REC*', b_hors_asgard := True) IS NULL
        INTO STRICT b ;
        
    r := r AND b ;
    RAISE NOTICE '57b-4 > %', r::text ;
    
    DROP ROLE "g_asgard_REC" ;
    
    -- #4
    SELECT count(*) = 1
        INTO STRICT b
        FROM z_asgard.gestion_schema_usr
        WHERE nom_schema = 'c_LIB air Ie'
            AND editeur = 'g_asgard REC*' ;
            
    r := r AND b ;
    RAISE NOTICE '57b-4b > %', r::text ;
    
    -- #5
    SELECT count(*) = 1
        INTO STRICT b
        FROM z_asgard_admin.asgard_diagnostic(ARRAY['c_LIB air Ie'])
        WHERE nom_schema = 'c_LIB air Ie' ;
    
    r := r AND b ;
    RAISE NOTICE '57b-5 > %', r::text ;
    
    -- #6
    SELECT count(*) = 1
        INTO STRICT b
        FROM z_asgard_admin.asgard_diagnostic(ARRAY['c_Bibliothèque'])
        WHERE nom_schema = 'c_Bibliothèque' ;
    
    r := r AND b ;
    RAISE NOTICE '57b-6 > %', r::text ;
    
    -- #7
    SELECT count(*) = 1
        INTO STRICT b
        FROM z_asgard.gestion_schema_usr
        WHERE nom_schema = 'c_Archives'
            AND producteur = 'g_asgard REC*' ;
    
    r := r AND b ;
    RAISE NOTICE '57b-7 > %', r::text ;
    
    -- #8
    SELECT count(*) = 0
        INTO STRICT b
        FROM z_asgard_admin.asgard_diagnostic(ARRAY['c_Archives'])
        WHERE nom_schema = 'c_Archives' ;
    
    r := r AND b ;
    RAISE NOTICE '57b-8 > %', r::text ;
    
    -- #9
    SELECT count(*) = 1
        INTO STRICT b
        FROM pg_operator
        WHERE oprnamespace = quote_ident('c_LABO{rat}oire')::regnamespace::oid
            AND oprowner = quote_ident('g_asgard REC*')::regrole::oid ;
    
    r := r AND b ;
    RAISE NOTICE '57b-9 > %', r::text ;
    
    -- #10
    IF NOT has_database_privilege('g_asgard REC*', current_database()::text, 'CREATE')
    THEN
        r := False ;
        RAISE NOTICE '57b-10 > %', r::text ;
    END IF ;
    
    ------ suppression ------
    SELECT z_asgard_admin.asgard_reaffecte_role('g_asgard REC*', b_hors_asgard := True) IS NULL
        INTO STRICT b ;
        
    r := r AND b ;
    RAISE NOTICE '57b-11 > %', r::text ;
    
    DROP ROLE "g_asgard REC*" ;
    
    -- #11
    SELECT count(*) = 1
        INTO STRICT b
        FROM z_asgard.gestion_schema_usr
        WHERE nom_schema = 'c_Archives'
            AND producteur = 'g_admin' ;
    
    r := r AND b ;
    RAISE NOTICE '57b-11b > %', r::text ;
    
    -- #12
    SELECT count(*) = 1
        INTO STRICT b
        FROM z_asgard.gestion_schema_usr
        WHERE nom_schema = 'c_LIB air Ie'
            AND editeur IS NULL ;
            
    r := r AND b ;
    RAISE NOTICE '57b-12 > %', r::text ;
    
    -- #13
    SELECT count(*) = 0
        INTO STRICT b
        FROM z_asgard_admin.asgard_diagnostic() ;
    
    r := r AND b ;
    RAISE NOTICE '57b-13 > %', r::text ;
    
    -- #14
    SELECT count(*) = 1
        INTO STRICT b
        FROM pg_operator
        WHERE oprnamespace = quote_ident('c_LABO{rat}oire')::regnamespace::oid
            AND oprowner = quote_ident('g_admin')::regrole::oid ;
    
    r := r AND b ;
    RAISE NOTICE '57b-14 > %', r::text ;
    
    DROP SCHEMA "c_Bibliothèque" CASCADE ;
    DROP SCHEMA "c_LIB air Ie" CASCADE ;
    DROP SCHEMA "c_LABO{rat}oire" CASCADE ;
    DROP SCHEMA "c_Archives" CASCADE ;
    DELETE FROM z_asgard.gestion_schema_usr ;

    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                            e_detl = PG_EXCEPTION_DETAIL ;
    RAISE NOTICE '%', e_mssg
        USING DETAIL = e_detl ;
        
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t057b() IS 'ASGARD recette. TEST : (asgard_reaffecte_role) transmission/suppression des droits (hors privilèges par défaut).' ;

-- FUNCTION: z_asgard_recette.t058()

CREATE OR REPLACE FUNCTION z_asgard_recette.t058()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
   e_mssg text ;
   e_detl text ;
BEGIN

    CREATE ROLE g_asgard_rec_1 ;
    CREATE ROLE g_asgard_rec_2 ;

    CREATE SCHEMA c_bibliotheque AUTHORIZATION g_asgard_rec_1 ;
    CREATE SCHEMA c_librairie AUTHORIZATION g_asgard_rec_2 ;

    CREATE TABLE c_bibliotheque.table_1 (id serial PRIMARY KEY, nom text) ;
    CREATE MATERIALIZED VIEW c_librairie.vue_mat AS (SELECT * FROM c_bibliotheque.table_1) ;
    CREATE VIEW c_librairie.vue_spl AS (SELECT * FROM c_bibliotheque.table_1) ;
    
    -- #1
    SELECT count(*) = 2
        INTO b
        FROM z_asgard_admin.asgard_diagnostic() ;
        
    r := b ;
    RAISE NOTICE '58-1 > %', r::text ;

    -- #2
    SELECT count(*) = 1
        INTO b
        FROM z_asgard_admin.asgard_diagnostic(ARRAY['c_librairie'])
        WHERE nom_schema = 'c_librairie'
            AND typ_objet = 'vue'
            AND nom_objet = 'vue_spl'
            AND anomalie ~ ALL (ARRAY['membre', 'source', 'table_1']) ;
            
    r := r AND b ;
    RAISE NOTICE '58-2 > %', r::text ;
    
    -- #3
    SELECT count(*) = 1
        INTO b
        FROM z_asgard_admin.asgard_diagnostic(ARRAY['c_librairie'])
        WHERE nom_schema = 'c_librairie'
            AND typ_objet = 'vue matérialisée'
            AND nom_objet = 'vue_mat'
            AND anomalie ~ ALL (ARRAY['membre', 'source', 'table_1']) ;
            
    r := r AND b ;
    RAISE NOTICE '58-3 > %', r::text ;

    UPDATE z_asgard.gestion_schema_usr
        SET lecteur = 'g_asgard_rec_2'
        WHERE nom_schema = 'c_bibliotheque' ;

    -- #4
    SELECT count(*) = 0
        INTO b
        FROM z_asgard_admin.asgard_diagnostic() ;
        
    r := r AND b ;
    RAISE NOTICE '58-4 > %', r::text ;
    
    DROP SCHEMA c_bibliotheque CASCADE ;
    DROP SCHEMA c_librairie CASCADE ;
    DELETE FROM z_asgard.gestion_schema_usr ;
    
    DROP ROLE g_asgard_rec_1 ;
    DROP ROLE g_asgard_rec_2 ;

    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                            e_detl = PG_EXCEPTION_DETAIL ;
    RAISE NOTICE '%', e_mssg
        USING DETAIL = e_detl ;
        
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t058() IS 'ASGARD recette. TEST : (asgard_diagnostic) détection des droits manquants pour le producteur du schéma d''une vue sur les données sources.' ;

-- FUNCTION: z_asgard_recette.t058b()

CREATE OR REPLACE FUNCTION z_asgard_recette.t058b()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
   e_mssg text ;
   e_detl text ;
BEGIN

    CREATE ROLE "g_ASGARD_rec_1" ;
    CREATE ROLE "g_ASGARD_rec 2$" ;

    CREATE SCHEMA "c_Bibliothèque" AUTHORIZATION "g_ASGARD_rec_1" ;
    CREATE SCHEMA "c_Lib'rai rie" AUTHORIZATION "g_ASGARD_rec 2$" ;

    CREATE TABLE "c_Bibliothèque"."table 1" (id serial PRIMARY KEY, nom text) ;
    CREATE MATERIALIZED VIEW "c_Lib'rai rie"."VUE_MAT" AS (SELECT * FROM "c_Bibliothèque"."table 1") ;
    CREATE VIEW "c_Lib'rai rie"."vue*SPL" AS (SELECT * FROM "c_Bibliothèque"."table 1") ;
    
    -- #1
    SELECT count(*) = 2
        INTO b
        FROM z_asgard_admin.asgard_diagnostic() ;
        
    r := b ;
    RAISE NOTICE '58b-1 > %', r::text ;

    -- #2
    SELECT count(*) = 1
        INTO b
        FROM z_asgard_admin.asgard_diagnostic(ARRAY['c_Lib''rai rie'])
        WHERE nom_schema = 'c_Lib''rai rie'
            AND typ_objet = 'vue'
            AND nom_objet = 'vue*SPL'
            AND anomalie ~ ALL (ARRAY['membre', 'source', 'table 1']) ;
            
    r := r AND b ;
    RAISE NOTICE '58b-2 > %', r::text ;
    
    -- #3
    SELECT count(*) = 1
        INTO b
        FROM z_asgard_admin.asgard_diagnostic(ARRAY['c_Lib''rai rie'])
        WHERE nom_schema = 'c_Lib''rai rie'
            AND typ_objet = 'vue matérialisée'
            AND nom_objet = 'VUE_MAT'
            AND anomalie ~ ALL (ARRAY['membre', 'source', 'table 1']) ;
            
    r := r AND b ;
    RAISE NOTICE '58b-3 > %', r::text ;

    UPDATE z_asgard.gestion_schema_usr
        SET lecteur = 'g_ASGARD_rec 2$'
        WHERE nom_schema = 'c_Bibliothèque' ;

    -- #4
    SELECT count(*) = 0
        INTO b
        FROM z_asgard_admin.asgard_diagnostic() ;
        
    r := r AND b ;
    RAISE NOTICE '58b-4 > %', r::text ;
    
    DROP SCHEMA "c_Bibliothèque" CASCADE ;
    DROP SCHEMA "c_Lib'rai rie" CASCADE ;
    DELETE FROM z_asgard.gestion_schema_usr ;
    
    DROP ROLE "g_ASGARD_rec_1" ;
    DROP ROLE "g_ASGARD_rec 2$" ;

    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                            e_detl = PG_EXCEPTION_DETAIL ;
    RAISE NOTICE '%', e_mssg
        USING DETAIL = e_detl ;
        
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t058b() IS 'ASGARD recette. TEST : (asgard_diagnostic) détection des droits manquants pour le producteur du schéma d''une vue sur les données sources.' ;

-- FUNCTION: z_asgard_recette.t059()

CREATE OR REPLACE FUNCTION z_asgard_recette.t059()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
   e_mssg text ;
   e_detl text ;
BEGIN

    CREATE SCHEMA c_bibliotheque ;
    GRANT USAGE ON SCHEMA c_bibliotheque TO public ;
    
    CREATE SCHEMA c_librairie ;
    GRANT USAGE ON SCHEMA c_librairie TO public ;

    -- #1
    SELECT count(*) = 2
        INTO b
        FROM z_asgard_admin.asgard_diagnostic() ;
        
    r := b ;
    RAISE NOTICE '59-1 > %', r::text ;
    
    -- #2
    BEGIN
        PERFORM z_asgard_admin.asgard_diagnostic(ARRAY['c_bibliotheque', 'c_librairie_bis']) ;
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                                e_detl = PG_EXCEPTION_DETAIL ;
                                
        r := r AND (e_mssg ~ 'FDD1[.]' OR e_detl ~ 'FDD1[.]' OR False) ;
        RAISE NOTICE '59-2 > %', r::text ;
    END ;

    -- #3
    SELECT count(*) = 1
        INTO b
        FROM z_asgard_admin.asgard_diagnostic(ARRAY['c_bibliotheque']) ;
        
    r := r AND b ;
    RAISE NOTICE '59-3 > %', r::text ;
    
    -- #4
    SELECT count(*) = 2
        INTO b
        FROM z_asgard_admin.asgard_diagnostic(ARRAY['c_bibliotheque', 'c_librairie']) ;
        
    r := r AND b ;
    RAISE NOTICE '59-4 > %', r::text ;
    
    -- #5
    SELECT count(*) = 2
        INTO b
        FROM z_asgard_admin.asgard_diagnostic(ARRAY[]::text[]) ;
        
    r := r AND b ;
    RAISE NOTICE '59-5 > %', r::text ;
    
    -- #6
    SELECT count(*) = 2
        INTO b
        FROM z_asgard_admin.asgard_diagnostic(ARRAY[NULL]::text[]) ;
        
    r := r AND b ;
    RAISE NOTICE '59-6 > %', r::text ;
    
    -- #7
    SELECT count(*) = 2
        INTO b
        FROM z_asgard_admin.asgard_diagnostic(NULL) ;
        
    r := r AND b ;
    RAISE NOTICE '59-7 > %', r::text ;

    -- #8
    SELECT count(*) = 2
        INTO b
        FROM z_asgard_admin.asgard_diagnostic(ARRAY[NULL, NULL]::text[]) ;
        
    r := r AND b ;
    RAISE NOTICE '59-8 > %', r::text ;
    
    -- #9
    SELECT count(*) = 1
        INTO b
        FROM z_asgard_admin.asgard_diagnostic(ARRAY['c_bibliotheque', NULL]) ;
        
    r := r AND b ;
    RAISE NOTICE '59-9 > %', r::text ;
    
    -- #10
    SELECT count(*) = 1
        INTO b
        FROM z_asgard_admin.asgard_diagnostic(ARRAY[NULL, 'c_bibliotheque']) ;
        
    r := r AND b ;
    RAISE NOTICE '59-10 > %', r::text ;
    
    DROP SCHEMA c_bibliotheque ;
    DROP SCHEMA c_librairie ;
    DELETE FROM z_asgard.gestion_schema_usr ;

    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                            e_detl = PG_EXCEPTION_DETAIL ;
    RAISE NOTICE '%', e_mssg
        USING DETAIL = e_detl ;
        
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t059() IS 'ASGARD recette. TEST : (asgard_diagnostic) utilisation de la liste de schémas optionnelle.' ;

-- FUNCTION: z_asgard_recette.t059b()

CREATE OR REPLACE FUNCTION z_asgard_recette.t059b()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
   e_mssg text ;
   e_detl text ;
BEGIN

    CREATE SCHEMA "c_Bibliothèque" ;
    GRANT USAGE ON SCHEMA "c_Bibliothèque" TO public ;
    
    CREATE SCHEMA "c_LIB rai|rie" ;
    GRANT USAGE ON SCHEMA "c_LIB rai|rie" TO public ;

    -- #1
    SELECT count(*) = 2
        INTO b
        FROM z_asgard_admin.asgard_diagnostic() ;
        
    r := b ;
    RAISE NOTICE '59b-1 > %', r::text ;
    
    -- #2
    BEGIN
        PERFORM z_asgard_admin.asgard_diagnostic(ARRAY['c_Bibliothèque', '"c_LIB rai|rie"_bis']) ;
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                                e_detl = PG_EXCEPTION_DETAIL ;
                                
        r := r AND (e_mssg ~ 'FDD1[.]' OR e_detl ~ 'FDD1[.]' OR False) ;
        RAISE NOTICE '59b-2 > %', r::text ;
    END ;

    -- #3
    SELECT count(*) = 1
        INTO b
        FROM z_asgard_admin.asgard_diagnostic(ARRAY['c_Bibliothèque']) ;
        
    r := r AND b ;
    RAISE NOTICE '59b-3 > %', r::text ;
    
    -- #4
    SELECT count(*) = 2
        INTO b
        FROM z_asgard_admin.asgard_diagnostic(ARRAY['c_Bibliothèque', 'c_LIB rai|rie']) ;
        
    r := r AND b ;
    RAISE NOTICE '59b-4 > %', r::text ;
    
    -- #5
    SELECT count(*) = 2
        INTO b
        FROM z_asgard_admin.asgard_diagnostic(ARRAY[]::text[]) ;
        
    r := r AND b ;
    RAISE NOTICE '59b-5 > %', r::text ;
    
    -- #6
    SELECT count(*) = 2
        INTO b
        FROM z_asgard_admin.asgard_diagnostic(ARRAY[NULL]::text[]) ;
        
    r := r AND b ;
    RAISE NOTICE '59b-6 > %', r::text ;
    
    -- #7
    SELECT count(*) = 2
        INTO b
        FROM z_asgard_admin.asgard_diagnostic(NULL) ;
        
    r := r AND b ;
    RAISE NOTICE '59b-7 > %', r::text ;

    -- #8
    SELECT count(*) = 2
        INTO b
        FROM z_asgard_admin.asgard_diagnostic(ARRAY[NULL, NULL]::text[]) ;
        
    r := r AND b ;
    RAISE NOTICE '59b-8 > %', r::text ;
    
    -- #9
    SELECT count(*) = 1
        INTO b
        FROM z_asgard_admin.asgard_diagnostic(ARRAY['c_Bibliothèque', NULL]) ;
        
    r := r AND b ;
    RAISE NOTICE '59b-9 > %', r::text ;
    
    -- #10
    SELECT count(*) = 1
        INTO b
        FROM z_asgard_admin.asgard_diagnostic(ARRAY[NULL, 'c_Bibliothèque']) ;
        
    r := r AND b ;
    RAISE NOTICE '59b-10 > %', r::text ;
    
    DROP SCHEMA "c_Bibliothèque" ;
    DROP SCHEMA "c_LIB rai|rie" ;
    DELETE FROM z_asgard.gestion_schema_usr ;

    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                            e_detl = PG_EXCEPTION_DETAIL ;
    RAISE NOTICE '%', e_mssg
        USING DETAIL = e_detl ;
        
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t059b() IS 'ASGARD recette. TEST : (asgard_diagnostic) utilisation de la liste de schémas optionnelle.' ;


-- FUNCTION: z_asgard_recette.t060()

CREATE OR REPLACE FUNCTION z_asgard_recette.t060()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
   e_mssg text ;
   e_detl text ;
BEGIN

    CREATE ROLE g_asgard_rec1 ;
    CREATE ROLE g_asgard_rec2 ;
    CREATE ROLE g_asgard_rec3 ;
    CREATE ROLE g_asgard_rec4 ;

    CREATE SCHEMA c_bibliotheque ;
    CREATE TABLE c_bibliotheque.journal_du_mur (id serial PRIMARY KEY, jour date, entree text) ;
    
    UPDATE z_asgard.gestion_schema_usr
        SET editeur = 'g_asgard_rec1',
            lecteur = 'g_asgard_rec2'
        WHERE nom_schema = 'c_bibliotheque' ;
        
    GRANT INSERT ON TABLE c_bibliotheque.journal_du_mur TO g_asgard_rec2 WITH GRANT OPTION ;
    GRANT UPDATE ON TABLE c_bibliotheque.journal_du_mur TO g_asgard_rec1 WITH GRANT OPTION ;
    
    UPDATE z_asgard.gestion_schema_usr
        SET editeur = 'g_asgard_rec3',
            lecteur = 'g_asgard_rec4'
        WHERE nom_schema = 'c_bibliotheque' ;
        
    r := NOT has_table_privilege('g_asgard_rec2', 'c_bibliotheque.journal_du_mur', 'SELECT')
        AND NOT has_table_privilege('g_asgard_rec2', 'c_bibliotheque.journal_du_mur', 'INSERT')
        AND has_table_privilege('g_asgard_rec4', 'c_bibliotheque.journal_du_mur', 'SELECT')
        AND has_table_privilege('g_asgard_rec4', 'c_bibliotheque.journal_du_mur', 'INSERT')
        AND NOT has_table_privilege('g_asgard_rec4', 'c_bibliotheque.journal_du_mur', 'INSERT WITH GRANT OPTION')
        AND NOT has_table_privilege('g_asgard_rec1', 'c_bibliotheque.journal_du_mur', 'SELECT')
        AND NOT has_table_privilege('g_asgard_rec1', 'c_bibliotheque.journal_du_mur', 'INSERT')
        AND NOT has_table_privilege('g_asgard_rec1', 'c_bibliotheque.journal_du_mur', 'UPDATE')
        AND NOT has_table_privilege('g_asgard_rec1', 'c_bibliotheque.journal_du_mur', 'DELETE')
        AND has_table_privilege('g_asgard_rec3', 'c_bibliotheque.journal_du_mur', 'SELECT, INSERT, UPDATE, DELETE')
        AND NOT has_table_privilege('g_asgard_rec3', 'c_bibliotheque.journal_du_mur', 'UPDATE WITH GRANT OPTION') ;
        
    DROP SCHEMA c_bibliotheque CASCADE ;
    DELETE FROM z_asgard.gestion_schema_usr ;
    DROP ROLE g_asgard_rec1 ;
    DROP ROLE g_asgard_rec2 ;
    DROP ROLE g_asgard_rec3 ;
    DROP ROLE g_asgard_rec4 ;

    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                            e_detl = PG_EXCEPTION_DETAIL ;
    RAISE NOTICE '%', e_mssg
        USING DETAIL = e_detl ;
        
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t060() IS 'ASGARD recette. TEST : disparition des GRANT OPTION lors de la transmission des droits du lecteur et de l''éditeur.' ;

-- FUNCTION: z_asgard_recette.t060b()

CREATE OR REPLACE FUNCTION z_asgard_recette.t060b()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
   e_mssg text ;
   e_detl text ;
BEGIN

    CREATE ROLE "g_asgard_REC1" ;
    CREATE ROLE "g_asgard REC2" ;
    CREATE ROLE "g_asgard REC3*" ;
    CREATE ROLE "g_asgard_REC4" ;

    CREATE SCHEMA "c_Bibliothèque" ;
    CREATE TABLE "c_Bibliothèque"."Journal du Mur" (id serial PRIMARY KEY, jour date, entree text) ;
    
    UPDATE z_asgard.gestion_schema_usr
        SET editeur = 'g_asgard_REC1',
            lecteur = 'g_asgard REC2'
        WHERE nom_schema = 'c_Bibliothèque' ;
        
    GRANT INSERT ON TABLE "c_Bibliothèque"."Journal du Mur" TO "g_asgard REC2" WITH GRANT OPTION ;
    GRANT UPDATE ON TABLE "c_Bibliothèque"."Journal du Mur" TO "g_asgard_REC1" WITH GRANT OPTION ;
    
    UPDATE z_asgard.gestion_schema_usr
        SET editeur = 'g_asgard REC3*',
            lecteur = 'g_asgard_REC4'
        WHERE nom_schema = 'c_Bibliothèque' ;
        
    r := NOT has_table_privilege('g_asgard REC2', '"c_Bibliothèque"."Journal du Mur"', 'SELECT')
        AND NOT has_table_privilege('g_asgard REC2', '"c_Bibliothèque"."Journal du Mur"', 'INSERT')
        AND has_table_privilege('g_asgard_REC4', '"c_Bibliothèque"."Journal du Mur"', 'SELECT')
        AND has_table_privilege('g_asgard_REC4', '"c_Bibliothèque"."Journal du Mur"', 'INSERT')
        AND NOT has_table_privilege('g_asgard_REC4', '"c_Bibliothèque"."Journal du Mur"', 'INSERT WITH GRANT OPTION')
        AND NOT has_table_privilege('g_asgard_REC1', '"c_Bibliothèque"."Journal du Mur"', 'SELECT')
        AND NOT has_table_privilege('g_asgard_REC1', '"c_Bibliothèque"."Journal du Mur"', 'INSERT')
        AND NOT has_table_privilege('g_asgard_REC1', '"c_Bibliothèque"."Journal du Mur"', 'UPDATE')
        AND NOT has_table_privilege('g_asgard_REC1', '"c_Bibliothèque"."Journal du Mur"', 'DELETE')
        AND has_table_privilege('g_asgard REC3*', '"c_Bibliothèque"."Journal du Mur"', 'SELECT, INSERT, UPDATE, DELETE')
        AND NOT has_table_privilege('g_asgard REC3*', '"c_Bibliothèque"."Journal du Mur"', 'UPDATE WITH GRANT OPTION') ;
        
    DROP SCHEMA "c_Bibliothèque" CASCADE ;
    DELETE FROM z_asgard.gestion_schema_usr ;
    DROP ROLE "g_asgard_REC1" ;
    DROP ROLE "g_asgard REC2" ;
    DROP ROLE "g_asgard REC3*" ;
    DROP ROLE "g_asgard_REC4" ;

    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                            e_detl = PG_EXCEPTION_DETAIL ;
    RAISE NOTICE '%', e_mssg
        USING DETAIL = e_detl ;
        
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t060b() IS 'ASGARD recette. TEST : disparition des GRANT OPTION lors de la transmission des droits du lecteur et de l''éditeur.' ;

-- FUNCTION: z_asgard_recette.t061()

CREATE OR REPLACE FUNCTION z_asgard_recette.t061()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
   e_mssg text ;
   e_detl text ;
BEGIN

    CREATE ROLE g_asgard_rec1 ;
    CREATE ROLE g_asgard_rec2 ;

    CREATE SCHEMA c_bibliotheque ;
    CREATE TABLE c_bibliotheque.journal_du_mur (id serial PRIMARY KEY, jour date, entree text) ;
    
    UPDATE z_asgard.gestion_schema_usr
        SET editeur = 'g_asgard_rec1',
            lecteur = 'g_asgard_rec2'
        WHERE nom_schema = 'c_bibliotheque' ;
        
    GRANT INSERT ON TABLE c_bibliotheque.journal_du_mur TO g_asgard_rec2 WITH GRANT OPTION ;
    GRANT UPDATE ON TABLE c_bibliotheque.journal_du_mur TO g_asgard_rec1 WITH GRANT OPTION ;
    
    PERFORM z_asgard.asgard_initialise_obj('c_bibliotheque', 'journal_du_mur', 'table') ;
        
    r := has_table_privilege('g_asgard_rec2', 'c_bibliotheque.journal_du_mur', 'SELECT')
        AND NOT has_table_privilege('g_asgard_rec2', 'c_bibliotheque.journal_du_mur', 'INSERT')
        AND has_table_privilege('g_asgard_rec1', 'c_bibliotheque.journal_du_mur', 'SELECT, INSERT, UPDATE, DELETE')
        AND NOT has_table_privilege('g_asgard_rec1', 'c_bibliotheque.journal_du_mur', 'UPDATE WITH GRANT OPTION') ;
        
    DROP SCHEMA c_bibliotheque CASCADE ;
    DELETE FROM z_asgard.gestion_schema_usr ;
    DROP ROLE g_asgard_rec1 ;
    DROP ROLE g_asgard_rec2 ;

    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                            e_detl = PG_EXCEPTION_DETAIL ;
    RAISE NOTICE '%', e_mssg
        USING DETAIL = e_detl ;
        
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t061() IS 'ASGARD recette. TEST : (asgard_initialise_obj) suppression des GRANT OPTION.' ;

-- FUNCTION: z_asgard_recette.t061b()

CREATE OR REPLACE FUNCTION z_asgard_recette.t061b()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
   e_mssg text ;
   e_detl text ;
BEGIN

    CREATE ROLE "g_asgard_REC1" ;
    CREATE ROLE "g_asgard REC2" ;

    CREATE SCHEMA "c_Bibliothèque" ;
    CREATE TABLE "c_Bibliothèque"."Journal du Mur" (id serial PRIMARY KEY, jour date, entree text) ;
    
    UPDATE z_asgard.gestion_schema_usr
        SET editeur = 'g_asgard_REC1',
            lecteur = 'g_asgard REC2'
        WHERE nom_schema = 'c_Bibliothèque' ;
        
    GRANT INSERT ON TABLE "c_Bibliothèque"."Journal du Mur" TO "g_asgard REC2" WITH GRANT OPTION ;
    GRANT UPDATE ON TABLE "c_Bibliothèque"."Journal du Mur" TO "g_asgard_REC1" WITH GRANT OPTION ;
    
    PERFORM z_asgard.asgard_initialise_obj('c_Bibliothèque', 'Journal du Mur', 'table') ;
        
    r := has_table_privilege('g_asgard REC2', '"c_Bibliothèque"."Journal du Mur"', 'SELECT')
        AND NOT has_table_privilege('g_asgard REC2', '"c_Bibliothèque"."Journal du Mur"', 'INSERT')
        AND has_table_privilege('g_asgard_REC1', '"c_Bibliothèque"."Journal du Mur"', 'SELECT, INSERT, UPDATE, DELETE')
        AND NOT has_table_privilege('g_asgard_REC1', '"c_Bibliothèque"."Journal du Mur"', 'UPDATE WITH GRANT OPTION') ;
        
    DROP SCHEMA "c_Bibliothèque" CASCADE ;
    DELETE FROM z_asgard.gestion_schema_usr ;
    DROP ROLE "g_asgard_REC1" ;
    DROP ROLE "g_asgard REC2" ;

    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                            e_detl = PG_EXCEPTION_DETAIL ;
    RAISE NOTICE '%', e_mssg
        USING DETAIL = e_detl ;
        
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t061b() IS 'ASGARD recette. TEST : (asgard_initialise_obj) suppression des GRANT OPTION.' ;


-- FUNCTION: z_asgard_recette.t062()

CREATE OR REPLACE FUNCTION z_asgard_recette.t062()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
   e_mssg text ;
   e_detl text ;
BEGIN
    
    CREATE ROLE g_asgard_rec1 ;
    CREATE ROLE g_asgard_rec2 ;

    CREATE SCHEMA c_bibliotheque ;
    CREATE TABLE c_bibliotheque.journal_du_mur (id serial PRIMARY KEY, jour date, entree text) ;
    
    UPDATE z_asgard.gestion_schema_usr
        SET editeur = 'g_asgard_rec1',
            lecteur = 'g_asgard_rec2'
        WHERE nom_schema = 'c_bibliotheque' ;
        
    GRANT INSERT ON TABLE c_bibliotheque.journal_du_mur TO g_asgard_rec2 WITH GRANT OPTION ;
    GRANT UPDATE ON TABLE c_bibliotheque.journal_du_mur TO g_asgard_rec1 WITH GRANT OPTION ;
    
    PERFORM z_asgard.asgard_initialise_schema('c_bibliotheque') ;
        
    r := has_table_privilege('g_asgard_rec2', 'c_bibliotheque.journal_du_mur', 'SELECT')
        AND NOT has_table_privilege('g_asgard_rec2', 'c_bibliotheque.journal_du_mur', 'INSERT')
        AND has_table_privilege('g_asgard_rec1', 'c_bibliotheque.journal_du_mur', 'SELECT, INSERT, UPDATE, DELETE')
        AND NOT has_table_privilege('g_asgard_rec1', 'c_bibliotheque.journal_du_mur', 'UPDATE WITH GRANT OPTION') ;
        
    DROP SCHEMA c_bibliotheque CASCADE ;
    DELETE FROM z_asgard.gestion_schema_usr ;
    DROP ROLE g_asgard_rec1 ;
    DROP ROLE g_asgard_rec2 ;

    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                            e_detl = PG_EXCEPTION_DETAIL ;
    RAISE NOTICE '%', e_mssg
        USING DETAIL = e_detl ;
        
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t062() IS 'ASGARD recette. TEST : (asgard_initialise_schema) suppression des GRANT OPTION.' ;


-- FUNCTION: z_asgard_recette.t062b()

CREATE OR REPLACE FUNCTION z_asgard_recette.t062b()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
   e_mssg text ;
   e_detl text ;
BEGIN

    CREATE ROLE "g_asgard_REC1" ;
    CREATE ROLE "g_asgard REC2" ;

    CREATE SCHEMA "c_Bibliothèque" ;
    CREATE TABLE "c_Bibliothèque"."Journal du Mur" (id serial PRIMARY KEY, jour date, entree text) ;
    
    UPDATE z_asgard.gestion_schema_usr
        SET editeur = 'g_asgard_REC1',
            lecteur = 'g_asgard REC2'
        WHERE nom_schema = 'c_Bibliothèque' ;
        
    GRANT INSERT ON TABLE "c_Bibliothèque"."Journal du Mur" TO "g_asgard REC2" WITH GRANT OPTION ;
    GRANT UPDATE ON TABLE "c_Bibliothèque"."Journal du Mur" TO "g_asgard_REC1" WITH GRANT OPTION ;
    
    PERFORM z_asgard.asgard_initialise_schema('c_Bibliothèque') ;
        
    r := has_table_privilege('g_asgard REC2', '"c_Bibliothèque"."Journal du Mur"', 'SELECT')
        AND NOT has_table_privilege('g_asgard REC2', '"c_Bibliothèque"."Journal du Mur"', 'INSERT')
        AND has_table_privilege('g_asgard_REC1', '"c_Bibliothèque"."Journal du Mur"', 'SELECT, INSERT, UPDATE, DELETE')
        AND NOT has_table_privilege('g_asgard_REC1', '"c_Bibliothèque"."Journal du Mur"', 'UPDATE WITH GRANT OPTION') ;
        
    DROP SCHEMA "c_Bibliothèque" CASCADE ;
    DELETE FROM z_asgard.gestion_schema_usr ;
    DROP ROLE "g_asgard_REC1" ;
    DROP ROLE "g_asgard REC2" ;

    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                            e_detl = PG_EXCEPTION_DETAIL ;
    RAISE NOTICE '%', e_mssg
        USING DETAIL = e_detl ;
        
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t062b() IS 'ASGARD recette. TEST : (asgard_initialise_schema) suppression des GRANT OPTION.' ;


-- FUNCTION: z_asgard_recette.t063()

CREATE OR REPLACE FUNCTION z_asgard_recette.t063()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
   e_mssg text ;
   e_detl text ;
BEGIN
    
    CREATE ROLE g_asgard_rec1 ;
    CREATE ROLE g_asgard_rec2 ;

    CREATE SCHEMA c_bibliotheque ;
    CREATE TABLE c_bibliotheque.journal_du_mur (id serial PRIMARY KEY, jour date, entree text) ;
    
    UPDATE z_asgard.gestion_schema_usr
        SET editeur = 'g_asgard_rec1',
            lecteur = 'g_asgard_rec2'
        WHERE nom_schema = 'c_bibliotheque' ;
        
    GRANT INSERT ON TABLE c_bibliotheque.journal_du_mur TO g_asgard_rec2 WITH GRANT OPTION ;
    GRANT UPDATE ON TABLE c_bibliotheque.journal_du_mur TO g_asgard_rec1 WITH GRANT OPTION ;
    
    PERFORM z_asgard_admin.asgard_initialise_all_schemas() ;
        
    r := has_table_privilege('g_asgard_rec2', 'c_bibliotheque.journal_du_mur', 'SELECT')
        AND NOT has_table_privilege('g_asgard_rec2', 'c_bibliotheque.journal_du_mur', 'INSERT')
        AND has_table_privilege('g_asgard_rec1', 'c_bibliotheque.journal_du_mur', 'SELECT, INSERT, UPDATE, DELETE')
        AND NOT has_table_privilege('g_asgard_rec1', 'c_bibliotheque.journal_du_mur', 'UPDATE WITH GRANT OPTION') ;
        
    DROP SCHEMA c_bibliotheque CASCADE ;
    PERFORM z_asgard_admin.asgard_sortie_gestion_schema('z_asgard') ;
    PERFORM z_asgard_admin.asgard_sortie_gestion_schema('z_asgard_admin') ;
    DELETE FROM z_asgard.gestion_schema_usr ;
    DROP ROLE g_asgard_rec1 ;
    DROP ROLE g_asgard_rec2 ;

    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                            e_detl = PG_EXCEPTION_DETAIL ;
    RAISE NOTICE '%', e_mssg
        USING DETAIL = e_detl ;
        
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t063() IS 'ASGARD recette. TEST : (asgard_initialise_all_schemas) suppression des GRANT OPTION.' ;


-- FUNCTION: z_asgard_recette.t063b()

CREATE OR REPLACE FUNCTION z_asgard_recette.t063b()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
   e_mssg text ;
   e_detl text ;
BEGIN

    CREATE ROLE "g_asgard_REC1" ;
    CREATE ROLE "g_asgard REC2" ;

    CREATE SCHEMA "c_Bibliothèque" ;
    CREATE TABLE "c_Bibliothèque"."Journal du Mur" (id serial PRIMARY KEY, jour date, entree text) ;
    
    UPDATE z_asgard.gestion_schema_usr
        SET editeur = 'g_asgard_REC1',
            lecteur = 'g_asgard REC2'
        WHERE nom_schema = 'c_Bibliothèque' ;
        
    GRANT INSERT ON TABLE "c_Bibliothèque"."Journal du Mur" TO "g_asgard REC2" WITH GRANT OPTION ;
    GRANT UPDATE ON TABLE "c_Bibliothèque"."Journal du Mur" TO "g_asgard_REC1" WITH GRANT OPTION ;
    
    PERFORM z_asgard_admin.asgard_initialise_all_schemas() ;
        
    r := has_table_privilege('g_asgard REC2', '"c_Bibliothèque"."Journal du Mur"', 'SELECT')
        AND NOT has_table_privilege('g_asgard REC2', '"c_Bibliothèque"."Journal du Mur"', 'INSERT')
        AND has_table_privilege('g_asgard_REC1', '"c_Bibliothèque"."Journal du Mur"', 'SELECT, INSERT, UPDATE, DELETE')
        AND NOT has_table_privilege('g_asgard_REC1', '"c_Bibliothèque"."Journal du Mur"', 'UPDATE WITH GRANT OPTION') ;
        
    DROP SCHEMA "c_Bibliothèque" CASCADE ;
    PERFORM z_asgard_admin.asgard_sortie_gestion_schema('z_asgard') ;
    PERFORM z_asgard_admin.asgard_sortie_gestion_schema('z_asgard_admin') ;
    DELETE FROM z_asgard.gestion_schema_usr ;
    DROP ROLE "g_asgard_REC1" ;
    DROP ROLE "g_asgard REC2" ;

    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                            e_detl = PG_EXCEPTION_DETAIL ;
    RAISE NOTICE '%', e_mssg
        USING DETAIL = e_detl ;
        
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t063b() IS 'ASGARD recette. TEST : (asgard_initialise_all_schemas) suppression des GRANT OPTION.' ;

-- FUNCTION: z_asgard_recette.t064()

CREATE OR REPLACE FUNCTION z_asgard_recette.t064()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
   e_mssg text ;
   e_detl text ;
BEGIN
    
    CREATE ROLE g_asgard_rec1 ;
    CREATE ROLE g_asgard_rec2 ;

    CREATE SCHEMA c_bibliotheque ;
    CREATE TABLE c_bibliotheque.journal_du_mur (id serial PRIMARY KEY, jour date, entree text) ;
    
    UPDATE z_asgard.gestion_schema_usr
        SET editeur = 'g_asgard_rec1',
            lecteur = 'g_asgard_rec2'
        WHERE nom_schema = 'c_bibliotheque' ;
        
    GRANT INSERT ON TABLE c_bibliotheque.journal_du_mur TO g_asgard_rec2 WITH GRANT OPTION ;
    GRANT UPDATE ON TABLE c_bibliotheque.journal_du_mur TO g_asgard_rec1 WITH GRANT OPTION ;
    
    SELECT
        count(*) FILTER (WHERE anomalie ~ ALL (ARRAY['GRANT.OPTION', 'INSERT', 'g_asgard_rec2'])) = 1
            AND count(*) FILTER (WHERE anomalie ~ ALL (ARRAY['GRANT.OPTION', 'UPDATE', 'g_asgard_rec1'])) = 1
            AND count(*) = 3
        INTO r
        FROM z_asgard_admin.asgard_diagnostic(ARRAY['c_bibliotheque']) ;
        
    DROP SCHEMA c_bibliotheque CASCADE ;
    DELETE FROM z_asgard.gestion_schema_usr ;
    DROP ROLE g_asgard_rec1 ;
    DROP ROLE g_asgard_rec2 ;

    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                            e_detl = PG_EXCEPTION_DETAIL ;
    RAISE NOTICE '%', e_mssg
        USING DETAIL = e_detl ;
        
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t064() IS 'ASGARD recette. TEST : (asgard_diagnostic) détection des GRANT OPTION.' ;


-- FUNCTION: z_asgard_recette.t064b()

CREATE OR REPLACE FUNCTION z_asgard_recette.t064b()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
   e_mssg text ;
   e_detl text ;
BEGIN

    CREATE ROLE "g_asgard_REC1" ;
    CREATE ROLE "g_asgard REC2" ;

    CREATE SCHEMA "c_Bibliothèque" ;
    CREATE TABLE "c_Bibliothèque"."Journal du Mur" (id serial PRIMARY KEY, jour date, entree text) ;
    
    UPDATE z_asgard.gestion_schema_usr
        SET editeur = 'g_asgard_REC1',
            lecteur = 'g_asgard REC2'
        WHERE nom_schema = 'c_Bibliothèque' ;
        
    GRANT INSERT ON TABLE "c_Bibliothèque"."Journal du Mur" TO "g_asgard REC2" WITH GRANT OPTION ;
    GRANT UPDATE ON TABLE "c_Bibliothèque"."Journal du Mur" TO "g_asgard_REC1" WITH GRANT OPTION ;
    
    SELECT
        count(*) FILTER (WHERE anomalie ~ ALL (ARRAY['GRANT.OPTION', 'INSERT', 'g_asgard.REC2'])) = 1
            AND count(*) FILTER (WHERE anomalie ~ ALL (ARRAY['GRANT.OPTION', 'UPDATE', 'g_asgard_REC1'])) = 1
            AND count(*) = 3
        INTO r
        FROM z_asgard_admin.asgard_diagnostic(ARRAY['c_Bibliothèque']) ;
        
    DROP SCHEMA "c_Bibliothèque" CASCADE ;
    PERFORM z_asgard_admin.asgard_sortie_gestion_schema('z_asgard') ;
    PERFORM z_asgard_admin.asgard_sortie_gestion_schema('z_asgard_admin') ;
    DELETE FROM z_asgard.gestion_schema_usr ;
    DROP ROLE "g_asgard_REC1" ;
    DROP ROLE "g_asgard REC2" ;

    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                            e_detl = PG_EXCEPTION_DETAIL ;
    RAISE NOTICE '%', e_mssg
        USING DETAIL = e_detl ;
        
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t064b() IS 'ASGARD recette. TEST : (asgard_diagnostic) détection des GRANT OPTION.' ;


-- FUNCTION: z_asgard_recette.t065()

CREATE OR REPLACE FUNCTION z_asgard_recette.t065()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
   e_mssg text ;
   e_detl text ;
BEGIN

    CREATE ROLE g_asgard_rec1 ;
    
    EXECUTE 'GRANT CREATE, CONNECT ON DATABASE ' || current_database()::text || ' TO g_asgard_rec1' ;
    
    SELECT
        unnest(z_asgard_admin.asgard_reaffecte_role('g_asgard_rec1', b_hors_asgard := False))::text = current_database()::text
        INTO r ;

    PERFORM z_asgard_admin.asgard_reaffecte_role('g_asgard_rec1', b_hors_asgard := True) ;
    DROP ROLE g_asgard_rec1 ;
    
    RETURN coalesce(r, False) ;
    
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                            e_detl = PG_EXCEPTION_DETAIL ;
    RAISE NOTICE '%', e_mssg
        USING DETAIL = e_detl ;
        
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t065() IS 'ASGARD recette. TEST : (asgard_reaffecte_role) renvoie effectif de la dépendance par le test final lorsque le rôle a uniquement des privilèges sur la base elle-même.' ;

-- FUNCTION: z_asgard_recette.t065b()

CREATE OR REPLACE FUNCTION z_asgard_recette.t065b()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
   e_mssg text ;
   e_detl text ;
BEGIN

    CREATE ROLE "g_asgard_REC1" ;
    
    EXECUTE 'GRANT CREATE, CONNECT ON DATABASE ' || current_database()::text || ' TO "g_asgard_REC1"' ;
    
    SELECT
        unnest(z_asgard_admin.asgard_reaffecte_role('g_asgard_REC1', b_hors_asgard := False))::text = current_database()::text
        INTO r ;

    PERFORM z_asgard_admin.asgard_reaffecte_role('g_asgard_REC1', b_hors_asgard := True) ;
    DROP ROLE "g_asgard_REC1" ;
    
    RETURN coalesce(r, False) ;
    
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                            e_detl = PG_EXCEPTION_DETAIL ;
    RAISE NOTICE '%', e_mssg
        USING DETAIL = e_detl ;
        
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t065b() IS 'ASGARD recette. TEST : (asgard_reaffecte_role) renvoie effectif de la dépendance par le test final lorsque le rôle a uniquement des privilèges sur la base elle-même.' ;


-- FUNCTION: z_asgard_recette.t066()

CREATE OR REPLACE FUNCTION z_asgard_recette.t066()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
   e_mssg text ;
   e_detl text ;
   t record ;
BEGIN

    REVOKE USAGE ON SCHEMA z_asgard FROM g_consult ;

    FOR t IN (SELECT * FROM pg_catalog.pg_class WHERE relnamespace = 'z_asgard'::regnamespace AND relkind = ANY (ARRAY['v', 'r', 'm', 'f', 'p']))
    LOOP
        EXECUTE 'REVOKE ALL ON TABLE z_asgard.' || quote_ident(t.relname) || ' FROM g_consult' ;
    END LOOP ;
    
    PERFORM z_asgard.asgard_initialise_schema('z_asgard') ;
    
    SELECT count(*) = 0
        INTO b
        FROM z_asgard_admin.asgard_diagnostic() ;
        
    r := b ;
    
    FOR t IN (SELECT pg_class.oid FROM pg_catalog.pg_class WHERE relnamespace = 'z_asgard'::regnamespace AND relkind = ANY (ARRAY['v', 'r', 'm', 'f', 'p']))
    LOOP
        SELECT has_table_privilege('g_consult', t.oid, 'SELECT')
            INTO b ;
        r := r AND b ;
    END LOOP ;

    PERFORM z_asgard_admin.asgard_sortie_gestion_schema('z_asgard') ;

    RETURN r ;
    
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                            e_detl = PG_EXCEPTION_DETAIL ;
    RAISE NOTICE '%', e_mssg
        USING DETAIL = e_detl ;
        
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t066() IS 'ASGARD recette. TEST : (asgard_initialise_schema) restauration des privilèges de g_consult sur z_asgard.' ;


-- FUNCTION: z_asgard_recette.t067()

CREATE OR REPLACE FUNCTION z_asgard_recette.t067()
    RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
   b boolean ;
   r boolean ;
   e_mssg text ;
   e_detl text ;
BEGIN

    RETURN has_database_privilege('g_admin', current_database(), 'CREATE WITH GRANT OPTION') ;
    
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS e_mssg = MESSAGE_TEXT,
                            e_detl = PG_EXCEPTION_DETAIL ;
    RAISE NOTICE '%', e_mssg
        USING DETAIL = e_detl ;
        
    RETURN False ;
    
END
$_$;

COMMENT ON FUNCTION z_asgard_recette.t067() IS 'ASGARD recette. TEST : attribution de CREATE WITH GRANT OPTION sur la base à g_admin.' ;