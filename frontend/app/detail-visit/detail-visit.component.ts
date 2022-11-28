import { Component, OnInit, ViewChild, AfterViewInit, TemplateRef } from '@angular/core';
import { Router, ActivatedRoute } from '@angular/router';

import { MapService } from '@geonature_common/map/map.service';
import { GeojsonComponent } from '@geonature_common/map/geojson/geojson.component';

import { StoreService } from '../services/store.service';
import { ModuleConfig } from '../module.config';
import { DataService } from '../services/data.service';
import { ObserversService } from '../services/observers.service';

@Component({
  selector: 'pnx-detail-visit',
  templateUrl: 'detail-visit.component.html',
  styleUrls: ['./detail-visit.component.scss'],
})
export class DetailVisitComponent implements OnInit, AfterViewInit {
  public idVisit;
  public idSite;
  public sciname;
  public date;
  public perturbationsDisplay: string = '';
  public visitGrid = [];
  public observersDisplay: string = '';
  public rows = [];
  public dataListVisit = [];
  public comments;
  public meshes;

  @ViewChild('geojson')
  geojson: GeojsonComponent;
  @ViewChild('observersCellTpl')
  observersCellTpl: TemplateRef<any>;

  constructor(
    public activatedRoute: ActivatedRoute,
    private api: DataService,
    public mapService: MapService,
    private observersService: ObserversService,
    public router: Router,
    public storeService: StoreService
  ) {}

  ngOnInit() {
    this.activatedRoute.params.subscribe(params => {
      this.idSite = params.idSite;
      this.idVisit = params.idVisit;

      this.initializeStoreService();
      this.initializeDatatableCols();
      this.loadSite();
      this.loadVisit();
      this.loadOthersVisits();
    });
  }

  private initializeStoreService() {
    this.storeService.initialize();
    this.storeService.queryString = this.storeService.queryString.set(
      'id_base_visit',
      this.idVisit
    );
  }

  private initializeDatatableCols() {
    this.storeService.sftConfig.default_list_visit_columns.forEach(col => {
      if (col.prop === 'observers') {
        col.cellTemplate = this.observersCellTpl;
      }
    });
  }

  private loadSite() {
    this.api.getOneSite(this.idSite).subscribe(info => {
      this.sciname = info.sciname.label;
    });
  }

  private loadVisit() {
    this.api.getOneVisit(this.idVisit).subscribe(visit => {
      this.date = visit.visit_date_min;
      this.idSite = visit.id_base_site;
      this.comments = visit.comments;
      this.visitGrid = visit.cor_visit_grid;
      this.buildPertubationsDisplay(visit.cor_visit_perturbation);
      this.buildObserversDisplay(visit.observers);
      this.loadMeshes();
    });
  }

  private buildPertubationsDisplay(visitPerturbations) {
    let perturbationsLabels = visitPerturbations.map(
      visitPerturbation => visitPerturbation.nomenclature.label_default
    );
    this.perturbationsDisplay = 'aucune';
    if (perturbationsLabels.length > 0) {
      this.perturbationsDisplay = perturbationsLabels.join(', ') + '.';
    }
  }

  private buildObserversDisplay(observers) {
    this.observersDisplay = this.observersService
      .initialize()
      .addObservers(observers)
      .getObserversFull();
  }

  private loadOthersVisits() {
    this.api.getVisits({ id_base_site: this.idSite }).subscribe(data => {
      data.forEach(visit => {
        visit.observers = this.observersService
          .initialize()
          .addObservers(visit.observers)
          .getObserversAbbr();
        visit.observersFull = this.observersService.getObserversFull();

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
        visit.state = pres + 'P / ' + abs + 'A ';
      });

      this.dataListVisit = data;

      this.rows = this.dataListVisit.filter(data => {
        return data.id_base_visit.toString() !== this.idVisit;
      });
    });
  }

  private loadMeshes() {
    this.api
      .getMeshes(this.idSite, {
        id_area_type: this.storeService.sftConfig.id_type_maille,
      })
      .subscribe(data => {
        this.meshes = data;
        this.countGridTypes(data.features.length);
      });
  }

  private countGridTypes(meshesTotal) {
    if (this.visitGrid !== undefined) {
      this.visitGrid.forEach(grid => {
        if (grid.presence == true) {
          this.storeService.presence += 1;
        } else {
          this.storeService.absence += 1;
        }
      });
    }
    this.storeService.total = meshesTotal;
    this.storeService.computeNoVisitedMeshes();
  }

  ngAfterViewInit() {
    this.mapService.map.doubleClickZoom.disable();

    this.geojson.currentGeoJson$.subscribe(currentLayer => {
      this.mapService.map.fitBounds(currentLayer.getBounds());
    });
  }

  onEachFeature(feature, layer) {
    if (this.visitGrid !== undefined) {
      this.visitGrid.forEach(maille => {
        if (maille.id_area == feature.id) {
          if (maille.presence) {
            layer.setStyle(this.storeService.presenceStyle);
          } else {
            layer.setStyle(this.storeService.absenceStyle);
          }
        }
      });
    }
  }

  onEditHere() {
    this.activatedRoute.params.subscribe(params => {
      this.router.navigate([
        `${ModuleConfig.MODULE_URL}/sites`,
        this.idSite,
        'visits',
        params.idVisit,
        'edit',
      ]);
    });
  }

  onEditOther(id_visit) {
    this.router.navigate([
      `${ModuleConfig.MODULE_URL}/sites`,
      this.idSite,
      'visits',
      id_visit,
      'edit',
    ]);
  }

  onInfo(id_visit) {
    this.router.navigate([`${ModuleConfig.MODULE_URL}/sites`, this.idSite, 'visits', id_visit]);
  }
}
