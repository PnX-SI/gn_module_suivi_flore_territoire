from sqlalchemy import ForeignKey
from sqlalchemy.ext.associationproxy import association_proxy
from sqlalchemy.dialects.postgresql import UUID
from geoalchemy2 import Geometry


from geonature.utils.env import DB
from utils_flask_sqla.serializers import serializable
from utils_flask_sqla_geo.serializers import geoserializable
from utils_flask_sqla.generic import GenericQuery
from geonature.utils.utilsgeometry import shapeserializable
from geonature.core.gn_synthese.models import synthese_export_serialization
from geonature.core.gn_monitoring.models import (
    TBaseSites,
    TBaseVisits,
    corVisitObserver,
)
from geonature.core.ref_geo.models import LAreas
from pypnnomenclature.models import TNomenclatures
from pypnusershub.db.models import User


@serializable
@geoserializable
class TInfoSite(DB.Model):
    """
    Modèle d'une ZP
    """

    __tablename__ = "t_infos_site"
    __table_args__ = {"schema": "pr_monitoring_flora_territory"}

    id_infos_site = DB.Column(DB.Integer, primary_key=True)
    # fk gn_monitoring.base_site
    id_base_site = DB.Column(DB.Integer, ForeignKey(TBaseSites.id_base_site))
    base_site = DB.relationship(TBaseSites)
    geom = association_proxy("base_site", "geom")
    cd_nom = DB.Column(DB.Integer)

    def get_geofeature(self):
        return self.as_geofeature("geom", "id_infos_site")


class corVisitPerturbation(DB.Model):
    __tablename__ = "cor_visit_perturbation"
    __table_args__ = {"schema": "pr_monitoring_flora_territory"}
    id_base_visit = DB.Column(
        "id_base_visit",
        DB.Integer,
        ForeignKey("gn_monitoring.t_base_visits.id_base_visit"),
        primary_key=True,
    )
    id_nomenclature_perturbation = DB.Column(
        "id_nomenclature_perturbation",
        DB.Integer,
        ForeignKey(TNomenclatures.id_nomenclature),
        primary_key=True,
    )


@serializable
class CorVisitGrid(DB.Model):
    """
    Corespondance entre une maille et une visite
    """

    __tablename__ = "cor_visit_grid"
    __table_args__ = {"schema": "pr_monitoring_flora_territory"}

    id_area = DB.Column(DB.Integer, ForeignKey(LAreas.id_area), primary_key=True)
    id_base_visit = DB.Column(
        DB.Integer, ForeignKey(TBaseVisits.id_base_visit), primary_key=True
    )
    presence = DB.Column(DB.Boolean)
    uuid_base_visit = DB.Column(UUID(as_uuid=True))


@serializable
@shapeserializable
class TVisiteSFT(TBaseVisits):
    """
    Visite sur une ZP
    et corespondance avec ses mailles
    """

    __tablename__ = "t_base_visits"
    __table_args__ = {"schema": "gn_monitoring", "extend_existing": True}

    cor_visit_grid = DB.relationship(
        "CorVisitGrid",
        primaryjoin=(CorVisitGrid.id_base_visit == TBaseVisits.id_base_visit),
        foreign_keys=[CorVisitGrid.id_base_visit],
    )
    cor_visit_perturbation = DB.relationship(
        TNomenclatures,
        secondary=corVisitPerturbation.__table__,
        primaryjoin=(corVisitPerturbation.id_base_visit == TBaseVisits.id_base_visit),
        secondaryjoin=(
            corVisitPerturbation.id_nomenclature_perturbation
            == TNomenclatures.id_nomenclature
        ),
        foreign_keys=[
            corVisitPerturbation.id_base_visit,
            corVisitPerturbation.id_nomenclature_perturbation,
        ],
        viewonly=True
    )

    observers = DB.relationship(
        "User",
        secondary=corVisitObserver,
        primaryjoin=(corVisitObserver.c.id_base_visit == TBaseVisits.id_base_visit),
        secondaryjoin=(corVisitObserver.c.id_role == User.id_role),
        foreign_keys=[corVisitObserver.c.id_base_visit, corVisitObserver.c.id_role],
    )


@serializable
@geoserializable
@shapeserializable
class ExportVisits(DB.Model):
    __tablename__ = "export_visits"
    __table_args__ = {"schema": "pr_monitoring_flora_territory"}
    id_area = DB.Column(DB.Integer, primary_key=True)
    id_base_visit = DB.Column(DB.Integer, primary_key=True)
    id_base_site = DB.Column(DB.Integer)
    uuid_base_visit = DB.Column(UUID(as_uuid=True))
    visit_date_min = DB.Column(DB.DateTime)
    comments = DB.Column(DB.Unicode)
    geom = DB.Column(Geometry("GEOMETRY", 2154))
    presence = DB.Column(DB.Boolean)
    label_perturbation = DB.Column(DB.Unicode)
    observateurs = DB.Column(DB.Unicode)
    organisme = DB.Column(DB.Unicode)
    base_site_name = DB.Column(DB.Unicode)
    nom_valide = DB.Column(DB.Unicode)
    cd_nom = DB.Column(DB.Integer)
    area_name = DB.Column(DB.Unicode)
    id_type = DB.Column(DB.Integer)
