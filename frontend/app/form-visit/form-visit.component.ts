import { Component, OnInit, AfterViewInit, ViewChild } from '@angular/core';
import { FormGroup, FormBuilder, Validators } from '@angular/forms';
import { Router, ActivatedRoute } from '@angular/router';

import { NgbDateParserFormatter } from '@ng-bootstrap/ng-bootstrap';
import { ToastrService } from 'ngx-toastr';

import { CommonService } from '@geonature_common/service/common.service';
import { MapService } from '@geonature_common/map/map.service';
import { GeojsonComponent } from '@geonature_common/map/geojson/geojson.component';

import { DataService } from '../services/data.service';
import { StoreService } from '../services/store.service';
import { ModuleConfig } from '../module.config';

@Component({
  selector: 'pnx-form-visit',
  templateUrl: 'form-visit.component.html',
  styleUrls: ['./form-visit.component.scss'],
})
export class FormVisitComponent implements OnInit, AfterViewInit {
  public zps;
  public modifGrid;
  public sciname;
  public date;
  public idVisit;
  public idSite;
  public namePertur = [];
  public visitGrid = []; // Data on meshes
  public tabObserver = [];
  public visitModif = {}; // Visited meshes object
  public disabledAfterPost = false;
  public firstFileLayerMessage = true;

  @ViewChild('geojson')
  geojson: GeojsonComponent;

  constructor(
    public api: DataService,
    public activatedRoute: ActivatedRoute,
    public dateParser: NgbDateParserFormatter,
    public mapService: MapService,
    public router: Router,
    public storeService: StoreService,
    private toastr: ToastrService,
    private commonService: CommonService,
    public formBuilder: FormBuilder
  ) {}

  ngOnInit() {
    this.idSite = this.activatedRoute.snapshot.params['idSite'];
    this.idVisit = this.activatedRoute.snapshot.params['idVisit'];

    // Get Taxon name from site
    this.api.getInfoSite(this.idSite).subscribe(info => {
      this.sciname = info.sciname.label;
    });

    // Initialize
    this.modifGrid = this.initializeVisitForm();
    this.storeService.initialize();

    // Check if is an update or an insert
    if (this.idVisit !== undefined) {
      this.api.getOneVisit(this.idVisit).subscribe(element => {
        if (element.cor_visit_grid !== undefined) {
          this.visitGrid = element.cor_visit_grid;
        }

        // Count absence and presence of existing meshes
        if (this.visitGrid !== undefined) {
          this.visitGrid.forEach(grid => {
            if (grid.presence == true) {
              this.storeService.presence += 1;
            } else {
              this.storeService.absence += 1;
            }
          });
        }

        // Date
        this.date = element.visit_date_min;

        console.log("Perturbations:", element.cor_visit_perturbation)
        // Update data binded object
        this.modifGrid.patchValue({
          id_base_site: this.idSite,
          id_base_visit: this.idVisit,
          visit_date_min: this.dateParser.parse(this.date),
          visit_date_max: this.dateParser.parse(this.date),
          cor_visit_observer: element.observers,
          cor_visit_perturbation: element.cor_visit_perturbation.map(
            visitPerturbation => visitPerturbation.nomenclature
          ),
          cor_visit_grid: this.visitGrid,
          comments: element.comments,
        });
      });
    } else {
      this.visitGrid = [];
    }

    this.api
      .getMaille(this.idSite, { id_area_type: ModuleConfig.id_type_maille })
      .subscribe(data => {
        this.zps = data;
        this.geojson.currentGeoJson$.subscribe(currentLayer => {
          this.mapService.map.fitBounds(currentLayer.getBounds());
        });
        this.storeService.total = this.zps.features.length;
        this.storeService.getMailleNoVisit();
      });
  }

  private initializeVisitForm(): FormGroup {
    const formSuivi = this.formBuilder.group({
      id_base_site: null,
      id_base_visit: null,
      visit_date_min: [null, Validators.required],
      visit_date_max: null,
      cor_visit_observer: [null, Validators.required],
      cor_visit_perturbation: new Array(),
      cor_visit_grid: new Array(),
      comments: null,
    });
    return formSuivi;
  }

  ngAfterViewInit() {
    this.mapService.map.doubleClickZoom.disable();
  }

  onEachFeature(feature, layer) {
    if (this.visitGrid !== undefined) {
      this.visitGrid.forEach(maille => {
        if (maille.id_area == feature.id) {
          if (maille.presence) {
            layer.setStyle(this.storeService.myStylePresent);
          } else {
            layer.setStyle(this.storeService.myStyleAbsent);
          }
        }
      });
    }

    // Handle events on map meshes
    layer.on({
      click: event1 => {
        layer.setStyle(this.storeService.myStylePresent);

        if (feature.state == 2) {
          this.storeService.absence -= 1;
          this.storeService.presence += 1;
        } else if (feature.state == 1) {
          this.storeService.presence += 0;
        } else {
          this.storeService.presence += 1;
        }

        feature.state = 1;
        this.storeService.getMailleNoVisit();
        this.visitModif[feature.id] = true;
      },

      contextmenu: event2 => {
        layer.setStyle(this.storeService.myStyleAbsent);
        if (feature.state == 1) {
          this.storeService.presence -= 1;
          this.storeService.absence += 1;
        } else if (feature.state == 2) {
          this.storeService.absence += 0;
        } else {
          this.storeService.absence += 1;
        }

        feature.state = 2;
        this.storeService.getMailleNoVisit();
        this.visitModif[feature.id] = false;
      },

      dblclick: event3 => {
        layer.setStyle(this.mapService.originStyle);
        if (feature.state == 1) {
          this.storeService.presence -= 1;
        } else if (feature.state == 2) {
          this.storeService.absence -= 1;
        }

        feature.state = 0;
        this.storeService.getMailleNoVisit();
        this.visitModif[feature.id] = false;
      },
    });
  }

  // display help toaster for filelayer
  displayFileLayerInfoMessage() {
    if (this.firstFileLayerMessage) {
      this.commonService.translateToaster('info', 'Map.FileLayerInfoSynthese');
    }
    this.firstFileLayerMessage = false;
  }

  onVisual() {
    this.router.navigate([`${ModuleConfig.MODULE_URL}/sites`, this.idSite]);
  }

  onModif() {
    const formModif = Object.assign({}, this.modifGrid.value);
    formModif['id_base_site'] = this.idSite;

    formModif['visit_date_min'] = this.dateParser.format(
      this.modifGrid.controls.visit_date_min.value
    );
    formModif['visit_date_max'] = this.dateParser.format(
      this.modifGrid.controls.visit_date_min.value
    );

    for (let key in this.visitModif) {
      let idAreaUpdated = Number(key);
      let needToInsert = true;
      this.visitGrid.forEach(existingGrid => {
        if (existingGrid.id_area == idAreaUpdated) {
          existingGrid.presence = this.visitModif[key];
          needToInsert = false;
        }
      });
      if (needToInsert) {
        this.visitGrid.push({
          id_base_visit: Number(this.idVisit),
          presence: this.visitModif[key],
          id_area: Number(key),
        });
      }
    }

    formModif['cor_visit_grid'] = this.visitGrid;

    formModif['cor_visit_observer'] = formModif['cor_visit_observer'].map(obs => {
      return obs.id_role;
    });

    if (
      formModif['cor_visit_perturbation'] !== null &&
      formModif['cor_visit_perturbation'] !== undefined
    ) {
      formModif['cor_visit_perturbation'] = formModif['cor_visit_perturbation'].map(
        pertu => pertu.id_nomenclature
      );
    }

    formModif['comments'] = this.modifGrid.controls.comments.value;

    this.api.postVisit(formModif).subscribe(
      data => {
        this.toastr.success('Visite enregistrée', '', {
          positionClass: 'toast-top-center',
        });

        this.router.navigate([`${ModuleConfig.MODULE_URL}/sites`, this.idSite]);
      },
      error => {
        if (error.status === 403) {
          if (error.error.raisedError === 'PostYearError') {
            this.toastr.warning(
              'Veuillez plutôt éditer une ancienne visite ',
              'Une visite existe déjà sur ce site pour cette année !',
              {
                positionClass: 'toast-top-center',
                timeOut: 5000,
              }
            );
          } else {
            this.commonService.translateToaster('error', 'NotAllowed');
          }
        } else {
          this.commonService.translateToaster('error', 'ErrorMessage');
        }
      }
    );

    // Disable submit button after post
    this.disabledAfterPost = true;
  }
}
