import { Component, OnInit, ViewChild, AfterViewInit, TemplateRef} from "@angular/core";
import { FormGroup } from "@angular/forms";
import { Router, ActivatedRoute } from "@angular/router";

import { MapListService } from "@geonature_common/map-list/map-list.service";
import { MapService } from "@geonature_common/map/map.service";
import { GeojsonComponent } from "@geonature_common/map/geojson/geojson.component";

import { DataService } from "../services/data.service";

import { StoreService } from "../services/store.service";
import { ModuleConfig } from "../module.config";
import { ObserversService } from '../services/observers.service';

@Component({
  selector: "pnx-list-visit",
  templateUrl: "list-visit.component.html",
  styleUrls: ["./list-visit.component.scss"],
})
export class ListVisitComponent implements OnInit, AfterViewInit {
  public zps;
  public currentZp = {};
  public idSite;
  public visitGrid: FormGroup;
  public idVisit;
  public visits = [];
  public showDetails = false;
  public site;
  @ViewChild("geojson")
  geojson: GeojsonComponent;
  @ViewChild("observersCellTpl")
  observersCellTpl: TemplateRef<any>;

  constructor(
    public mapService: MapService,
    private _api: DataService,
    public activatedRoute: ActivatedRoute,
    public storeService: StoreService,
    public router: Router,
    public mapListService: MapListService,
    private observersService: ObserversService
  ) {}

  ngOnInit() {
    this.idSite = this.activatedRoute.snapshot.params["idSite"];
    this.storeService.initialize();
    this.storeService.queryString = this.storeService.queryString.set(
      "id_base_site",
      this.idSite
    );

    this.storeService.sftConfig.default_list_visit_columns.forEach((col) => {
      if (col.prop === "observers") {
        col.cellTemplate = this.observersCellTpl;
      }
    });

    this._api.getInfoSite(this.idSite).subscribe((info) => {
      this.site = info;

      // Hide 'détail' tab if name and description are empty.
      if (this.site.description !== "" || this.site.name !== "") {
        this.showDetails = true;
      }
    });

    this._api
      .getMaille(this.idSite, {
        id_area_type: this.storeService.sftConfig.id_type_maille,
      })
      .subscribe((nbMaille) => {
        this.storeService.total = nbMaille.features.length;
      });

    this._api.getVisits({ id_base_site: this.idSite }).subscribe((visits) => {
      this.computeVisitsInfos(visits);
      this.visits = visits;
    });
  }

  private computeVisitsInfos(visits) {
    visits.forEach((visit) => {
      this.observersService.initialize().addObservers(visit.observers);
      visit.observers = this.observersService.getObserversAbbr();
      visit.observersFull = this.observersService.getObserversFull();

      let pres = 0;
      let abs = 0;
      if (visit.cor_visit_grid !== undefined) {
        visit.cor_visit_grid.forEach((maille) => {
          if (maille.presence) {
            pres += 1;
          } else {
            abs += 1;
          }
        });
      }
      visit.state = pres + "P / " + abs + "A ";
    });
  }

  ngAfterViewInit() {
    this.mapService.map.doubleClickZoom.disable();

    const parameters = {
      id_base_site: this.idSite,
      id_application: ModuleConfig.MODULE_CODE,
    };
    this._api.getZp(parameters).subscribe(data => {
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
      `${ModuleConfig.MODULE_URL}/sites`,
      this.idSite,
      "visits",
      id_visit,
      "edit",
    ]);
  }

  onInfo(id_visit) {
    this.router.navigate([
      `${ModuleConfig.MODULE_URL}/sites`,
      this.idSite,
      "visits",
      id_visit,
    ]);
  }

  onAdd() {
    this.router.navigate([
      `${ModuleConfig.MODULE_URL}/sites`,
      this.idSite,
      "visits",
      "add",
    ]);
  }
}
