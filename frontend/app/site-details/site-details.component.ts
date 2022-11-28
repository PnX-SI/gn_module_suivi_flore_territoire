import { Component, OnInit, ViewChild, AfterViewInit, TemplateRef } from '@angular/core';
import { FormGroup } from '@angular/forms';
import { Router, ActivatedRoute } from '@angular/router';

import { MapListService } from '@geonature_common/map-list/map-list.service';
import { MapService } from '@geonature_common/map/map.service';
import { GeojsonComponent } from '@geonature_common/map/geojson/geojson.component';

import { DataService } from '../shared/services/data.service';

import { StoreService } from '../shared/services/store.service';
import { ModuleConfig } from '../module.config';
import { ObserversService } from '../shared/services/observers.service';
import { ConfigService } from '../shared/services/config.service';

@Component({
  selector: 'mft-site-details',
  templateUrl: 'site-details.component.html',
  styleUrls: ['./site-details.component.scss'],
})
export class SiteDetailsComponent implements OnInit, AfterViewInit {
  public idSite;
  public visitGrid: FormGroup;
  public idVisit;
  public visits = [];
  public showDetails = false;
  public site;
  public siteGeoJson;

  @ViewChild('geojson')
  geojson: GeojsonComponent;
  @ViewChild('observersCellTpl')
  observersCellTpl: TemplateRef<any>;

  constructor(
    private api: DataService,
    public activatedRoute: ActivatedRoute,
    public configService: ConfigService,
    public mapListService: MapListService,
    public mapService: MapService,
    private observersService: ObserversService,
    public router: Router,
    public storeService: StoreService,
  ) {}

  ngOnInit() {
    this.idSite = this.activatedRoute.snapshot.params['idSite'];
    this.storeService.initialize();
    this.storeService.queryString = this.storeService.queryString.set('id_base_site', this.idSite);

    this.configService.get('default_list_visit_columns').forEach(col => {
      if (col.prop === 'observers') {
        col.cellTemplate = this.observersCellTpl;
      }
    });

    this.api.getOneSite(this.idSite).subscribe(info => {
      this.site = info;

      // Hide 'détail' tab if name and description are empty.
      if (this.site.description !== '' || this.site.name !== '') {
        this.showDetails = true;
      }
    });

    this.api
      .getMeshes(this.idSite, {
        id_area_type: this.configService.get('id_type_maille'),
      })
      .subscribe(nbMaille => {
        this.storeService.total = nbMaille.features.length;
      });

    this.api.getVisits({ id_base_site: this.idSite }).subscribe(visits => {
      this.computeVisitsInfos(visits);
      this.visits = visits;
    });
  }

  private computeVisitsInfos(visits) {
    visits.forEach(visit => {
      this.observersService.initialize().addObservers(visit.observers);
      visit.observers = this.observersService.getObserversAbbr();
      visit.observersFull = this.observersService.getObserversFull();

      let presence = 0;
      let absence = 0;
      if (visit.cor_visit_grid !== undefined) {
        visit.cor_visit_grid.forEach(maille => {
          if (maille.presence) {
            presence += 1;
          } else {
            absence += 1;
          }
        });
      }
      visit.state = presence + 'P / ' + absence + 'A ';
    });
  }

  ngAfterViewInit() {
    this.mapService.map.doubleClickZoom.disable();
    this.loadSiteGeojsonData();
  }

  private loadSiteGeojsonData() {
    const parameters = { id_base_site: this.idSite };

    this.api.getSites(parameters).subscribe(geojsonData => {
      this.siteGeoJson = geojsonData;

      this.geojson.currentGeoJson$.subscribe(currentLayer => {
        this.mapService.map.fitBounds(currentLayer.getBounds());
      });
    });
  }

  onEdit(id_visit) {
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

  onAdd() {
    this.router.navigate([`${ModuleConfig.MODULE_URL}/sites`, this.idSite, 'visits', 'add']);
  }
}
