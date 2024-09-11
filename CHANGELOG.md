# Changelog

Any notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unpublished]


## [1.2.0] - 2024-08-20

### Added

- GeoNature 2.14 compatible
- CRUVED module permissions declaration in an Alembic branch. The rights are the same for visits and observations
- Added the `meshes_source`, `site_code_column` and `site_desc_column` parameters in `bin/config/imports_settings.sample.ini`
- Added the management of the end date of visits to the interface (detailed sheet and visit entry form)

### Changed

- Updated README.md and install.md
- The `dataset_id` and `observers_list_id` parameters in `settings.ini` become respectively `id_dataset` and `id_menu_list_user` in `conf_gn_module.toml` (see `config/conf_gn_module.sample.toml` for default values)
- The `check_user_cruved_visit` and `cruved_scope_for_user_in_module` functions are replaced by the `VisitAuthMixin` class containing methods that allow to retrieve user rights on data (CRUVED action + scope)
- The list of visits of a site now displays the end date of the visit if at least one of the visits has a different end date of the visit than its start date of the visit.
- A visit can now take place over several years
- ⚠️ The `pr_monitoring_flora_territory.export_visits` view has been fixed in order to export the end date of the visit. We did not use an Alembic revision for the update. It is necessary to update this view manually using Psql for example. See the SQL code of the view in the file [schema.sql](backend/gn_module_monitoring_flora_territory/migrations/data/schema.sql).


## [1.1.2] - 2022-11-30

### Changed

- CRUVED checking is now done at the level of all web services.
- Renamed all frontend components to clarify their use. Used the prefix "mft", short for "Monitoring Flora Territory".
- Module routes are now in a separate file.
- Gathered all shared frontend files in a _shared/_ folder.
- Updated the code allowing export to Shape format. Used non-deprecated method names.
- Refactored most of the frontend code.
- The site access button now occupies the first column of the list to avoid it being inaccessible on small screens.
- The list of sites is now sorted on the last visit column. The sites with the most recent visits are displayed first.
- On large screens, lists now occupy all available space.

### Fixed

- The map cells when editing a visit are now correctly initialized with presences and absences (#67).
- The presence and absence cells are correctly counted when editing a visit.
- The content of the attributes of the export Shape files are now correctly encoded in UTF-8. There is no longer a problem with accented characters.
- The verification of the year of the visit is now correctly performed and generates an information pop-up.
- Use of the REST format for web service paths.
- The verification of the rights authorizing a user to edit a visit is functional again.


## [1.1.1] - 2022-11-22

### Changed

- Changed the path of the web service `/export_visit` to `/visits/export` to better respect REST principles.
- The parameters of the web service `/visits/export` can now be used in combination.
- ⚠️ The view `pr_monitoring_flora_territory.export_visits` has been fixed to support sites without a municipality. We did not use an Alembic revision for the update. It is necessary to update this view manually using Psql for example. See the SQL code of the view in the file [schema.sql](backend/gn_module_monitoring_flora_territory/migrations/data/schema.sql).
- Added the saving of the taxon filter between two uses of the filters on the list of sites view.

### Fixed

- Allowed sites to not have an associated municipality in the case of sites outside France. Fixes the export of visits and the display of site information.
- Removed warnings related to the use of recursive mode with the `utils_flask_sqla` library.
- Fixed the management of disruptions in the edit form of a visit.


## [1.1.0] - 2022-11-22

### Added

- Added a default config file for all Bash scripts: `settings.default.ini`
- Added a default config file for import scripts: `imports_settings.default.ini`
- Saved the values ​​of the threads
