from geoalchemy2 import Geometry
from sqlalchemy import ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.ext.associationproxy import association_proxy

from apptax.taxonomie.models import Taxref
from geonature.core.gn_monitoring.models import (
    TBaseSites,
    TBaseVisits,
    corVisitObserver,
)
from geonature.core.ref_geo.models import LAreas
from geonature.utils.env import db
from geonature.utils.utilsgeometry import shapeserializable
from pypnnomenclature.models import TNomenclatures
from pypnusershub.db.models import User
from utils_flask_sqla.serializers import serializable
from utils_flask_sqla_geo.serializers import geoserializable


class MonitoringFloraTerritory(db.Model):
    """
    Module db master parent abstract class.
    Debug is more easy.
    """

    __abstract__ = True

    def __repr__(self):
        return str(self.__class__) + ": " + str(self.__dict__)

    def __str__(self):
        return str(self.__class__) + ": " + str(self.__dict__)



@serializable
@geoserializable
class SiteInfos(MonitoringFloraTerritory):
    __tablename__ = "t_infos_site"
    __table_args__ = {"schema": "pr_monitoring_flora_territory"}
    id_infos_site = db.Column(db.Integer, primary_key=True)
    id_base_site = db.Column(db.Integer, ForeignKey(TBaseSites.id_base_site))
    cd_nom = db.Column(db.Integer, ForeignKey(Taxref.cd_nom))

    base_site = db.relationship(TBaseSites)
    sciname = db.relationship(Taxref)

    geom = association_proxy("base_site", "geom")

    def get_geofeature(self):
        return self.as_geofeature("geom", "id_infos_site")

@serializable
class VisitPerturbation(MonitoringFloraTerritory):
    __tablename__ = "cor_visit_perturbation"
    __table_args__ = {"schema": "pr_monitoring_flora_territory"}
    id_base_visit = db.Column(
        "id_base_visit",
        db.Integer,
        ForeignKey(TBaseVisits.id_base_visit),
        primary_key=True,
    )
    id_nomenclature_perturbation = db.Column(
        "id_nomenclature_perturbation",
        db.Integer,
        ForeignKey(TNomenclatures.id_nomenclature),
        primary_key=True,
    )

    nomenclature = db.relationship(
        TNomenclatures,
        primaryjoin=(id_nomenclature_perturbation == TNomenclatures.id_nomenclature),
        foreign_keys=[id_nomenclature_perturbation],
        lazy="joined",
    )


@serializable
class VisitGrid(MonitoringFloraTerritory):
    __tablename__ = "cor_visit_grid"
    __table_args__ = {"schema": "pr_monitoring_flora_territory"}
    id_area = db.Column(db.Integer, ForeignKey(LAreas.id_area), primary_key=True)
    id_base_visit = db.Column(db.Integer, ForeignKey(TBaseVisits.id_base_visit), primary_key=True)
    presence = db.Column(db.Boolean)
    uuid_base_visit = db.Column(UUID(as_uuid=True))


@serializable
@shapeserializable
class Visit(TBaseVisits):
    __tablename__ = "t_base_visits"
    __table_args__ = {"schema": "gn_monitoring", "extend_existing": True}

    def __repr__(self):
        return str(self.__class__) + ": " + str(self.__dict__)

    def __str__(self):
        return str(self.__class__) + ": " + str(self.__dict__)

    #id_base_visit = db.Column(db.Integer, primary_key=True)
    cor_visit_grid = db.relationship(
        VisitGrid,
        primaryjoin=(VisitGrid.id_base_visit == TBaseVisits.id_base_visit),
        foreign_keys=[VisitGrid.id_base_visit],
    )
    cor_visit_perturbation = db.relationship(VisitPerturbation, lazy="joined")
    observers = db.relationship(
        "User",
        secondary=corVisitObserver,
        primaryjoin=(corVisitObserver.c.id_base_visit == TBaseVisits.id_base_visit),
        secondaryjoin=(corVisitObserver.c.id_role == User.id_role),
        foreign_keys=[corVisitObserver.c.id_base_visit, corVisitObserver.c.id_role],
    )


@serializable
@geoserializable
@shapeserializable
class VisitsExport(MonitoringFloraTerritory):
    __tablename__ = "export_visits"
    __table_args__ = {"schema": "pr_monitoring_flora_territory"}
    id_area = db.Column(db.Integer, primary_key=True)
    id_base_visit = db.Column(db.Integer, primary_key=True)
    id_base_site = db.Column(db.Integer)
    uuid_base_visit = db.Column(UUID(as_uuid=True))
    visit_date_min = db.Column(db.DateTime)
    comments = db.Column(db.Unicode)
    geom = db.Column(Geometry("GEOMETRY", 2154))
    presence = db.Column(db.Boolean)
    label_perturbation = db.Column(db.Unicode)
    observateurs = db.Column(db.Unicode)
    organisme = db.Column(db.Unicode)
    base_site_name = db.Column(db.Unicode)
    nom_valide = db.Column(db.Unicode)
    cd_nom = db.Column(db.Integer)
    area_name = db.Column(db.Unicode)
    id_type = db.Column(db.Integer)
