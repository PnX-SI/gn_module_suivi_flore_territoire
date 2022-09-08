-----------------------------------------------------------------------
-- Utility functions
-----------------------------------------------------------------------

CREATE OR REPLACE FUNCTION pr_priority_flora.get_life_stage(phenologyId INTEGER)
    RETURNS INTEGER
    LANGUAGE plpgsql
    IMMUTABLE
AS
$function$
    -- Function that return the id of nomenclature "STADE_VIE"
    -- following the Priority Flore phenology code.
    -- USAGE: SELECT pr_priority_flora.get_life_stage(1);
    DECLARE
        phenologyCode VARCHAR;
        lifeStage INTEGER;
    BEGIN
        SELECT INTO phenologyCode
        FROM ref_nomenclatures.get_cd_nomenclature(phenologyId) ;

        IF (phenologyCode = '1') THEN
            SELECT ref_nomenclatures.get_id_nomenclature('STADE_VIE', '18') INTO lifeStage ;
        ELSIF (phenologyCode = '2') THEN
            SELECT ref_nomenclatures.get_id_nomenclature('STADE_VIE', '25') INTO lifeStage ;
        ELSIF (phenologyCode = '3') THEN
            SELECT ref_nomenclatures.get_id_nomenclature('STADE_VIE', '5') INTO lifeStage ;
        ELSIF (phenologyCode = '4') THEN
            SELECT ref_nomenclatures.get_id_nomenclature('STADE_VIE', '2') INTO lifeStage ;
        ELSIF (phenologyCode = '5') THEN
            SELECT ref_nomenclatures.get_id_nomenclature('STADE_VIE', '19') INTO lifeStage ;
        ELSIF (phenologyCode = '6') THEN
            SELECT ref_nomenclatures.get_id_nomenclature('STADE_VIE', '20') INTO lifeStage ;
        ELSIF (phenologyCode = '7') THEN
            SELECT ref_nomenclatures.get_id_nomenclature('STADE_VIE', '0') INTO lifeStage ;
        ELSIF (phenologyCode = '8') THEN
            SELECT ref_nomenclatures.get_id_nomenclature('STADE_VIE', '1') INTO lifeStage ;
        ELSE
            SELECT ref_nomenclatures.get_id_nomenclature('STADE_VIE', '0') INTO lifeStage ;
        END IF ;
        RETURN lifeStage ;
    END;
$function$ ;


CREATE OR REPLACE FUNCTION pr_priority_flora.get_counting_type(countingId INTEGER)
    RETURNS INTEGER
    LANGUAGE plpgsql
    IMMUTABLE
AS
$function$
    -- Function that return the id of nomenclature "TYP_DENBR"
    -- following the Priority Flore counting code.
    -- USAGE: SELECT pr_priority_flora.get_counting_type(1);
    DECLARE
        countingTypeCode VARCHAR;
        countingTypeId INTEGER;
    BEGIN
        SELECT INTO countingTypeCode
        FROM ref_nomenclatures.get_cd_nomenclature(countingId) ;

        IF (countingTypeCode = '1') THEN
            -- Recensement exhaustif
            SELECT ref_nomenclatures.get_id_nomenclature('TYP_DENBR', 'Co') INTO countingTypeId ;
        ELSIF (countingTypeCode = '2') THEN
            -- Échantillonage
            SELECT ref_nomenclatures.get_id_nomenclature('TYP_DENBR', 'Es') INTO countingTypeId ;
        ELSIF (countingTypeCode = '9') THEN
            -- Aucun comptage
            SELECT ref_nomenclatures.get_id_nomenclature('TYP_DENBR', 'NSP') INTO countingTypeId ;
        ELSE
            SELECT ref_nomenclatures.get_id_nomenclature('TYP_DENBR', 'NSP') INTO countingTypeId ;
        END IF ;
        RETURN countingTypeId ;
    END;
$function$ ;


CREATE OR REPLACE FUNCTION pr_priority_flora.get_observers_ids(prospectZoneId BIGINT)
    RETURNS INT[]
    LANGUAGE plpgsql
    IMMUTABLE
AS
$function$
    -- Function that return an array of observers ids (t_roles.id_role) of a prospect zone.
    -- USAGE: SELECT pr_priority_flora.get_observers_ids(t_zprospect.id_zp);
    DECLARE
    	currentObserversIds INT[];

    BEGIN
	    -- Get current observers id in prospect zones linked observers table
	    SELECT array_agg(c.id_role) INTO currentObserversIds
	    FROM pr_priority_flora.cor_zp_obs AS c
        WHERE c.id_zp = prospectZoneId ;

        RETURN currentObserversIds ;
    END;
$function$ ;


CREATE OR REPLACE FUNCTION pr_priority_flora.build_observers(
    prospectZoneId BIGINT,
    operation VARCHAR DEFAULT NULL,
    oberserverId INTEGER DEFAULT NULL
)
    RETURNS VARCHAR
    LANGUAGE plpgsql
    IMMUTABLE
AS
$function$
    -- Function that return the observers names (with organism name) of a prospect zone concatened
    -- into a string.
    -- USAGE:
    -- concat current observers :
    --      SELECT pr_priority_flora.build_observers(t_zprospect.id_zp);
    -- concat current observers and delete one by id role :
    --      SELECT pr_priority_flora.build_observers(t_zprospect.id_zp, 'DELETE', t_roles.id_role);
    -- concat current observers and add one by id role :
    --      SELECT pr_priority_flora.build_observers(t_zprospect.id_zp, 'INSERT', t_roles.id_role);
    DECLARE
    	currentObserversIds INT[];
        observers VARCHAR;

    BEGIN
	    -- Get current observers id in prospect zones linked observers table
	    SELECT pr_priority_flora.get_observers_ids(prospectZoneId) INTO currentObserversIds ;

        -- Remove or add observer who is processing from current observers id list
        IF (operation = 'DELETE') THEN
			SELECT ARRAY(
                SELECT unnest(currentObserversIds)
                EXCEPT SELECT unnest(ARRAY[oberserverId]::INT[])
            ) INTO currentObserversIds ;
		ELSIF (operation = 'INSERT') THEN
			SELECT currentObserversIds || ARRAY[oberserverId]::INT[] INTO currentObserversIds;
		END IF;

        -- Build observers string aggregation
        SELECT INTO observers array_to_string(
            array_agg(
            	r.prenom_role || ' ' || UPPER(r.nom_role) || ' ('|| bo.nom_organisme || ')'
            	ORDER BY r.nom_role ASC, r.prenom_role ASC
            ),
             ', '
        )
        FROM utilisateurs.t_roles AS r
            JOIN utilisateurs.bib_organismes AS bo
            	ON (r.id_organisme = bo.id_organisme)
        WHERE r.id_role = ANY(currentObserversIds) ;

        RETURN observers ;
    END;
$function$ ;


CREATE OR REPLACE FUNCTION pr_priority_flora.get_taxon_name(prospectZoneId BIGINT)
    RETURNS VARCHAR
    LANGUAGE plpgsql
    IMMUTABLE
AS
$function$
    -- Function that return the taxon name of a prospect zone.
    -- USAGE: SELECT pr_priority_flora.get_taxon_name(t_zprospect.id_zp);
    DECLARE
        taxonName VARCHAR;
    BEGIN
        SELECT INTO taxonName t.nom_valide
        FROM pr_priority_flora.t_zprospect AS zp
            JOIN taxonomie.taxref AS t
                ON t.cd_nom = zp.cd_nom
        WHERE zp.id_zp = prospectZoneId ;

        RETURN taxonName ;
    END;
$function$ ;


-----------------------------------------------------------------------
-- Fonction Trigger: add link between observations and roles (observers) in Synthese
-----------------------------------------------------------------------

CREATE OR REPLACE FUNCTION pr_priority_flora.add_synthese_observers()
RETURNS trigger AS
$BODY$
    DECLARE
        presenceArea RECORD;
        idSynthese INTEGER;
        concatenedObservers VARCHAR;
    BEGIN
        -- Build observers concatened list
        SELECT INTO concatenedObservers pr_priority_flora.build_observers(NEW.id_zp, TG_OP, NEW.id_role) ;

        -- Loop on every presence area of the prospect zone. If this prospect zones
        -- has no presence area, the loop not start.
        FOR presenceArea IN (
            SELECT ap.id_ap
            FROM pr_priority_flora.t_zprospect AS zp
                JOIN pr_priority_flora.t_apresence AS ap
                    ON ap.id_zp = zp.id_zp
            WHERE ap.id_zp = NEW.id_zp
        ) LOOP
            -- Get Syntese id
            SELECT INTO idSynthese id_synthese
            FROM gn_synthese.synthese
            WHERE id_source = pr_priority_flora.get_source_id()
                AND entity_source_pk_value = CAST(presenceArea.id_ap AS VARCHAR) ;

            -- Add link between an observation and an observer/user (=role)
            INSERT INTO gn_synthese.cor_observer_synthese (
                id_synthese,
                id_role
            ) VALUES (
                idSynthese,
                NEW.id_role
            ) ;

            -- Update observers fields in Synthese
            UPDATE gn_synthese.synthese SET
                observers = concatenedObservers,
                determiner = concatenedObservers,
                last_action = 'U'
            WHERE id_synthese = idSynthese ;
        END LOOP;

        RETURN NULL;  -- Result is ignored since this is an AFTER trigger
    END;
$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;


-----------------------------------------------------------------------
-- Fonction Trigger: delete link between observations and roles (observers) in Synthese
-----------------------------------------------------------------------

CREATE OR REPLACE FUNCTION pr_priority_flora.delete_synthese_observers()
RETURNS trigger AS
$BODY$
    DECLARE
        presenceArea RECORD;
        idSynthese INTEGER;
        concatenedObservers VARCHAR;
    BEGIN
        -- Build observers concatened list
        SELECT INTO concatenedObservers pr_priority_flora.build_observers(OLD.id_zp, TG_OP, OLD.id_role) ;

        -- Loop on every presence area of the prospect zone. If this prospect zones
        -- has no presence area, the loop not start.
        FOR presenceArea IN (
            SELECT ap.id_ap
            FROM pr_priority_flora.t_zprospect AS zp
                JOIN pr_priority_flora.t_apresence AS ap
                    ON ap.id_zp = zp.id_zp
            WHERE ap.id_zp = OLD.id_zp
        ) LOOP
            -- Get Syntese id
            SELECT INTO idSynthese id_synthese
            FROM gn_synthese.synthese
            WHERE id_source = pr_priority_flora.get_source_id()
                AND entity_source_pk_value = CAST(presenceArea.id_ap AS VARCHAR) ;

            -- Delete link between an observation and an observer/user (=role)
            DELETE FROM gn_synthese.cor_observer_synthese
            WHERE id_synthese = idSynthese
                AND id_role = OLD.id_role ;

            -- Update observers fields in Synthese
            UPDATE gn_synthese.synthese SET
                observers = concatenedObservers,
                determiner = concatenedObservers,
                last_action = 'U'
            WHERE id_synthese = idSynthese ;
        END LOOP ;

        RETURN NULL ; -- Result is ignored since this is an AFTER trigger
    END;
$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;


-----------------------------------------------------------------------
-- Fonction Trigger: add presence area in Synthese
-----------------------------------------------------------------------

CREATE OR REPLACE FUNCTION pr_priority_flora.insert_synthese_ap()
RETURNS trigger AS
$BODY$
    DECLARE
        prospectZone RECORD;
        concatenedObservers VARCHAR;
        observersList INT[];
        idSynthese INT;

    BEGIN
        -- Get prospect Zone record
        SELECT INTO prospectZone *
        FROM pr_priority_flora.t_zprospect
        WHERE id_zp = NEW.id_zp ;

        -- Build observers concatened list
        SELECT INTO concatenedObservers pr_priority_flora.build_observers(NEW.id_zp) ;

        -- Create new observation into Synthese
        INSERT INTO gn_synthese.synthese (
            unique_id_sinp,
            unique_id_sinp_grp,
            id_source,
            id_module,
            entity_source_pk_value,
            id_dataset,
            id_nomenclature_geo_object_nature,
            id_nomenclature_grp_typ,
            id_nomenclature_obs_technique,
            id_nomenclature_bio_status,
            id_nomenclature_bio_condition,
            id_nomenclature_naturalness,
            id_nomenclature_exist_proof,
            id_nomenclature_diffusion_level,
            id_nomenclature_life_stage,
            id_nomenclature_sex,
            id_nomenclature_obj_count,
            id_nomenclature_type_count,
            id_nomenclature_observation_status,
            id_nomenclature_blurring,
            id_nomenclature_source_status,
            id_nomenclature_info_geo_type,
            count_min,
            count_max,
            cd_nom,
            nom_cite,
            meta_v_taxref,
            altitude_min,
            altitude_max,
            the_geom_4326, -- EPSG 4326
            the_geom_point,-- EPSG 4326
            the_geom_local, -- EPSG 2154
            date_min,
            date_max,
            observers,
            determiner,
            comment_description,
            last_action
        ) VALUES (
            NEW.uuid_ap,
            prospectZone.uuid_zp,
            pr_priority_flora.get_source_id(),
            gn_commons.get_id_module_bycode(:moduleCode),
            NEW.id_ap,
            prospectZone.id_dataset,
            ref_nomenclatures.get_id_nomenclature('NAT_OBJ_GEO','In'),
            ref_nomenclatures.get_id_nomenclature('TYP_GRP','OBS'),
            ref_nomenclatures.get_id_nomenclature('METH_OBS','0'),
            ref_nomenclatures.get_id_nomenclature('STATUT_BIO','1'),
            ref_nomenclatures.get_id_nomenclature('ETA_BIO','2'),
            ref_nomenclatures.get_id_nomenclature('NATURALITE','1'),
            ref_nomenclatures.get_id_nomenclature('PREUVE_EXIST','2'),
            ref_nomenclatures.get_id_nomenclature('NIV_PRECIS','5'),
            pr_priority_flora.get_life_stage(NEW.id_nomenclature_phenology),
            ref_nomenclatures.get_id_nomenclature('SEXE','6'),
            ref_nomenclatures.get_id_nomenclature('OBJ_DENBR','NSP'),
            pr_priority_flora.get_counting_type(NEW.id_nomenclature_counting),
            ref_nomenclatures.get_id_nomenclature('STATUT_OBS','Pr'),
            ref_nomenclatures.get_id_nomenclature('DEE_FLOU','NON'),
            ref_nomenclatures.get_id_nomenclature('STATUT_SOURCE','Te'),
            ref_nomenclatures.get_id_nomenclature('TYP_INF_GEO','1'),
            NEW.total_min,-- count_min
            NEW.total_max,-- count_max
            prospectZone.cd_nom,
            pr_priority_flora.get_taxon_name(NEW.id_zp),
            gn_commons.get_default_parameter('taxref_version'),
            NEW.altitude_min,-- altitude_min
            NEW.altitude_max,-- altitude_max
            NEW.geom_4326,
            NEW.geom_point_4326,
            NEW.geom_local,
            prospectZone.date_min,-- date_min
            prospectZone.date_max,-- date_max
            concatenedObservers,-- observers
            concatenedObservers,-- determiner
            NEW.comment,
            'C'
        ) RETURNING id_synthese INTO idSynthese ;

       	-- Get current observers list of id role
        SELECT INTO observersList pr_priority_flora.get_observers_ids(NEW.id_zp) ;

        -- Add link between an observation and an observer/user (=role)
        INSERT INTO gn_synthese.cor_observer_synthese (id_synthese, id_role)
       		SELECT idSynthese, UNNEST(observersList) ;

        RETURN NULL; -- Result is ignored since this is an AFTER trigger
    END;
$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;


-----------------------------------------------------------------------
-- Fonction Trigger: update presence area in Synthese
-----------------------------------------------------------------------

CREATE OR REPLACE FUNCTION pr_priority_flora.update_synthese_ap()
RETURNS trigger AS
$BODY$
    BEGIN
        -- Update synthese
        UPDATE gn_synthese.synthese SET
            entity_source_pk_value = NEW.id_ap,
            unique_id_sinp = NEW.uuid_ap,
            id_nomenclature_type_count = pr_priority_flora.get_counting_type(NEW.id_nomenclature_counting),
            id_nomenclature_life_stage =  pr_priority_flora.get_life_stage(NEW.id_nomenclature_phenology),
            altitude_min = NEW.altitude_min,
            altitude_max = NEW.altitude_max,
            count_min = NEW.total_min,
            count_max = NEW.total_max,
            comment_description = NEW.comment,
            the_geom_4326 = NEW.geom_4326,
            the_geom_local = NEW.geom_local,
            the_geom_point = NEW.geom_point_4326,
            last_action = 'U'
        WHERE id_source = pr_priority_flora.get_source_id()
            AND entity_source_pk_value = CAST(OLD.id_ap AS VARCHAR) ;

        RETURN NULL; -- Result is ignored since this is an AFTER trigger
    END;
$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;


-----------------------------------------------------------------------
-- Function Trigger: delete presence area in Synthese
-----------------------------------------------------------------------

CREATE OR REPLACE FUNCTION pr_priority_flora.delete_synthese_ap()
RETURNS trigger AS
$BODY$
    -- Il n'y a pas de trigger delete sur la table t_zprospect parce qu'il
    -- y a un delete cascade dans la fk id_zp de t_apresence
    -- donc si on supprime la zp, on supprime sa ou ses AP et donc ce trigger
    -- sera déclanché et fera le ménage dans la table gn_synthese.synthese
    BEGIN
        -- Delete entry in gn_synthese.synthese
        DELETE FROM gn_synthese.synthese
        WHERE id_source = pr_priority_flora.get_source_id()
            AND entity_source_pk_value = CAST(OLD.id_ap AS VARCHAR) ;

        RETURN NULL; -- Result is ignored since this is an AFTER trigger
    END;
$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;


-----------------------------------------------------------------------
-- Function Trigger: update prospect zone in Synthese
-----------------------------------------------------------------------

CREATE OR REPLACE FUNCTION pr_priority_flora.update_synthese_zp()
RETURNS trigger AS
$BODY$
    DECLARE
        presenceArea RECORD;

    BEGIN
        FOR presenceArea IN (
            SELECT ap.id_ap
            FROM pr_priority_flora.t_zprospect AS zp
                JOIN pr_priority_flora.t_apresence AS ap
                    ON ap.id_zp = zp.id_zp
            WHERE ap.id_zp = NEW.id_zp
        )  LOOP
            -- Update synthese
            UPDATE gn_synthese.synthese SET
                unique_id_sinp_grp = NEW.uuid_zp,
                cd_nom = NEW.cd_nom,
                nom_cite = pr_priority_flora.get_taxon_name(NEW.id_zp),
                date_min = NEW.date_min,
                date_max = NEW.date_max,
                last_action = 'U'
            WHERE id_source = pr_priority_flora.get_source_id()
                AND entity_source_pk_value = CAST(presenceArea.id_ap AS VARCHAR) ;
        END LOOP;

        RETURN NULL; -- Result is ignored since this is an AFTER trigger
    END;
$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;


-----------------------------------------------------------------------
-- Triggers: Syntheses triggers
-----------------------------------------------------------------------

CREATE TRIGGER tri_insert_synthese_observer
    AFTER INSERT ON pr_priority_flora.cor_zp_obs
    FOR EACH ROW
    EXECUTE PROCEDURE pr_priority_flora.add_synthese_observers() ;

CREATE TRIGGER tri_delete_synthese_observer
    AFTER DELETE ON pr_priority_flora.cor_zp_obs
    FOR EACH ROW
    EXECUTE PROCEDURE pr_priority_flora.delete_synthese_observers() ;

CREATE TRIGGER tri_insert_synthese_ap
    AFTER INSERT ON pr_priority_flora.t_apresence
    FOR EACH ROW
    EXECUTE PROCEDURE pr_priority_flora.insert_synthese_ap() ;

CREATE TRIGGER tri_update_synthese_ap
    AFTER UPDATE ON pr_priority_flora.t_apresence
    FOR EACH ROW
    -- Do something only if a field has changed
    WHEN (
       OLD.uuid_ap IS DISTINCT FROM NEW.uuid_ap
       OR OLD.id_zp IS DISTINCT FROM NEW.id_zp
	   OR OLD.id_nomenclature_counting IS DISTINCT FROM NEW.id_nomenclature_counting
	   OR OLD.id_nomenclature_phenology IS DISTINCT FROM NEW.id_nomenclature_phenology
	   OR OLD.altitude_min IS DISTINCT FROM NEW.altitude_min
	   OR OLD.altitude_max IS DISTINCT FROM NEW.altitude_max
	   OR OLD.total_min IS DISTINCT FROM NEW.total_min
	   OR OLD.total_max IS DISTINCT FROM NEW.total_max
	   OR OLD."comment" IS DISTINCT FROM NEW."comment"
	   OR OLD.geom_4326 IS DISTINCT FROM NEW.geom_4326
	   OR OLD.geom_local IS DISTINCT FROM NEW.geom_local
	   OR OLD.geom_point_4326 IS DISTINCT FROM NEW.geom_point_4326
	)
    EXECUTE PROCEDURE pr_priority_flora.update_synthese_ap() ;

CREATE TRIGGER tri_delete_synthese_ap
    AFTER DELETE ON pr_priority_flora.t_apresence
    FOR EACH ROW
    EXECUTE PROCEDURE pr_priority_flora.delete_synthese_ap() ;

CREATE TRIGGER tri_update_synthese_zp
    AFTER UPDATE ON pr_priority_flora.t_zprospect
    FOR EACH ROW
    -- Do something only if a field has changed
    WHEN (
    	OLD.uuid_zp IS DISTINCT FROM NEW.uuid_zp
    	OR OLD.cd_nom IS DISTINCT FROM NEW.cd_nom
    	OR OLD.date_min IS DISTINCT FROM NEW.date_min
    	OR OLD.date_max IS DISTINCT FROM NEW.date_max
    )
    EXECUTE PROCEDURE pr_priority_flora.update_synthese_zp() ;
