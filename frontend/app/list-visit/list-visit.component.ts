import { Component, OnInit, ViewChild, AfterViewInit } from "@angular/core";
import { FormGroup } from "@angular/forms";
import { Router, ActivatedRoute } from "@angular/router";

import { MapListService } from "@geonature_common/map-list/map-list.service";
import { MapService } from "@geonature_common/map/map.service";
import { GeojsonComponent } from "@geonature_common/map/geojson/geojson.component";

import { DataService } from "../services/data.service";

import { StoreService } from "../services/store.service";
import { ModuleConfig } from "../module.config";

@Component({
  selector: "pnx-list-visit",
  templateUrl: "list-visit.component.html",
  styleUrls: ["./list-visit.component.scss"]
})
export class ListVisitComponent implements OnInit, AfterViewInit {
  public zps;
  public nomTaxon;
  public currentZp = {};
  public idSite;
  public visitGrid: FormGroup;
  public idVisit;
  public rows = [];
  public show = false;
  public nomCommune;
  public nomSite;
  public descriSite;
  @ViewChild("geojson")
  geojson: GeojsonComponent;

  constructor(
    public mapService: MapService,
    private _api: DataService,
    public activatedRoute: ActivatedRoute,
    public storeService: StoreService,
    public router: Router,
    public mapListService: MapListService
  ) {}

  ngOnInit() {
    this.idSite = this.activatedRoute.snapshot.params["idSite"];

    this.storeService.queryString = this.storeService.queryString.set(
      "id_base_site",
      this.idSite
    );

    this._api.getZp({ id_base_site: this.idSite }).subscribe(info => {
      info.features.forEach(el => {
        this.nomSite = el.properties.base_site.base_site_name;
        this.descriSite = el.properties.base_site.base_site_description;

        if (this.descriSite !== "" || this.nomSite !== "") {
          // masquer bloc 'détail' si les champs Nom et Description sont vides
          this.show = true;
        }
        this.nomCommune = el.properties.nom_commune;
      });
    });

    this._api
      .getMaille(this.idSite, {
        id_area_type: this.storeService.sftConfig.id_type_maille
      })
      .subscribe(nbMaille => {
        this.storeService.total = nbMaille.features.length;
      });

    this._api.getVisits({ id_base_site: this.idSite }).subscribe(data => {
      data.forEach(visit => {
        let fullName;
        visit.observers.forEach(obs => {
          fullName = obs.nom_role + " " + obs.prenom_role;
        });
        visit.observers = fullName;
        let pres = 0;
        let abs = 0;

        if (visit.cor_visit_grid !== undefined) {
          visit.cor_visit_grid.forEach(maille => {
            if (maille.presence) {
              pres += 1;
            } else {
              abs += 1;
            }
          });
        }

        visit.state = pres + "P / " + abs + "A ";
      });

      this.rows = data;
    });
  }

  ngAfterViewInit() {
    this.mapService.map.doubleClickZoom.disable();

    const parametre = {
      id_base_site: this.idSite,
      id_application: ModuleConfig.ID_MODULE
    };

    this._api.getZp(parametre).subscribe(data => {
      this.nomTaxon = data.features[0].properties.nom_taxon;

      this.zps = data;
      this.geojson.currentGeoJson$.subscribe(currentLayer => {
        this.mapService.map.fitBounds(currentLayer.getBounds());
      });
    });
  }

  onEachFeature(feature, layer) {
    this.currentZp = feature.id;
  }

  onEdit(id_visit) {
    this.router.navigate([
      `${ModuleConfig.MODULE_URL}/editVisit`,
      this.idSite,
      "visit",
      id_visit
    ]);
  }

  onInfo(id_visit) {
    this.router.navigate([`${ModuleConfig.MODULE_URL}/infoVisit`, id_visit]);
  }

  onAdd() {
    this.router.navigate([`${ModuleConfig.MODULE_URL}/editVisit`, this.idSite]);
  }
}
