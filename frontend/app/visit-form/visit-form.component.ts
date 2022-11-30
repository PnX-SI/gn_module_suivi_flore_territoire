import { Component, OnInit, AfterViewInit, ViewChild } from '@angular/core';
import { FormGroup, FormBuilder, Validators } from '@angular/forms';
import { Router, ActivatedRoute } from '@angular/router';

import { NgbDateParserFormatter, NgbModal } from '@ng-bootstrap/ng-bootstrap';
import { ToastrService } from 'ngx-toastr';

import { CommonService } from '@geonature_common/service/common.service';
import { MapService } from '@geonature_common/map/map.service';
import { GeojsonComponent } from '@geonature_common/map/geojson/geojson.component';

import { DataService } from '../shared/services/data.service';
import { StoreService } from '../shared/services/store.service';
import { ModuleConfig } from '../module.config';
import { ConfigService } from '../shared/services/config.service';

@Component({
  selector: 'mft-visit-form',
  templateUrl: 'visit-form.component.html',
  styleUrls: ['./visit-form.component.scss'],
})
export class VisitFormComponent implements OnInit, AfterViewInit {
  public idVisit;
  public idSite;
  private updateMode: boolean = false;
  public sciname;
  public date;
  public visitForm: FormGroup;
  public visitGrid = []; // Data on meshes
  private observers = [];
  private perturbations = [];
  private comments;
  public meshes;
  public updatedMeshes = {}; // Visited meshes object
  public disabledAfterPost = false;
  public firstFileLayerMessage = true;

  @ViewChild('geojson')
  geojson: GeojsonComponent;

  constructor(
    public api: DataService,
    public activatedRoute: ActivatedRoute,
    private commonService: CommonService,
    public configService: ConfigService,
    public dateParser: NgbDateParserFormatter,
    public formBuilder: FormBuilder,
    public mapService: MapService,
    private modalService: NgbModal,
    public router: Router,
    public storeService: StoreService,
    private toastr: ToastrService
  ) {}

  ngOnInit() {
    this.idSite = this.activatedRoute.snapshot.params['idSite'];
    this.idVisit = this.activatedRoute.snapshot.params['idVisit'];

    // Initialize
    this.initializeVisitForm();
    this.loadSite();

    // Check if is an update or an insert
    if (this.idVisit !== undefined) {
      this.updateMode = true;
      this.loadVisit();
    } else {
      this.loadMeshes();
    }
  }

  private initializeVisitForm() {
    this.storeService.initialize();

    this.visitForm = this.formBuilder.group({
      id_base_site: null,
      id_base_visit: null,
      visit_date_min: [null, Validators.required],
      visit_date_max: null,
      cor_visit_observer: [null, Validators.required],
      cor_visit_perturbation: new Array(),
      cor_visit_grid: new Array(),
      comments: null,
    });
  }

  private loadSite() {
    // Get Taxon name from site
    this.api.getOneSite(this.idSite).subscribe(info => {
      this.sciname = info.sciname.label;
    });
  }

  private loadVisit() {
    this.api.getOneVisit(this.idVisit).subscribe(visit => {
      this.date = visit.visit_date_min;
      this.visitGrid = visit.cor_visit_grid !== undefined ? visit.cor_visit_grid : [];
      this.observers = visit.observers;
      this.perturbations = visit.cor_visit_perturbation.map(
        visitPerturbation => visitPerturbation.nomenclature
      );
      this.comments = visit.comments;
      this.loadMeshes();
      this.patchVisitForm();
    });
  }

  private loadMeshes() {
    this.api
      .getMeshes(this.idSite, { id_area_type: this.configService.get('id_type_maille') })
      .subscribe(data => {
        this.meshes = data;
        this.countGridTypes(this.meshes.features.length);
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

  private patchVisitForm() {
    this.visitForm.patchValue({
      id_base_site: this.idSite,
      id_base_visit: this.idVisit,
      visit_date_min: this.dateParser.parse(this.date),
      visit_date_max: this.dateParser.parse(this.date),
      cor_visit_observer: this.observers,
      cor_visit_perturbation: this.perturbations,
      cor_visit_grid: this.visitGrid,
      comments: this.comments,
    });
  }

  ngAfterViewInit() {
    this.mapService.map.doubleClickZoom.disable();

    this.geojson.currentGeoJson$.subscribe(currentLayer => {
      this.mapService.map.fitBounds(currentLayer.getBounds());
    });
  }

  onEachFeature(feature, layer) {
    // Initialize feature and layer
    feature.state = 'UNDEFINED';
    if (this.visitGrid !== undefined) {
      this.visitGrid.forEach(mesh => {
        if (mesh.id_area == feature.id) {
          if (mesh.presence) {
            layer.setStyle(this.storeService.presenceStyle);
            feature.state = 'PRESENCE';
          } else {
            layer.setStyle(this.storeService.absenceStyle);
            feature.state = 'ABSENCE';
          }
        }
      });
    }

    // Handle events on map meshes
    layer.on({
      click: () => {
        if (feature.state == 'ABSENCE') {
          this.storeService.absence -= 1;
          this.storeService.presence += 1;
        } else if (feature.state == 'UNDEFINED') {
          this.storeService.presence += 1;
        }

        feature.state = 'PRESENCE';
        layer.setStyle(this.storeService.presenceStyle);
        this.storeService.computeNoVisitedMeshes();
        this.updatedMeshes[feature.id] = true;
      },

      contextmenu: () => {
        if (feature.state == 'PRESENCE') {
          this.storeService.presence -= 1;
          this.storeService.absence += 1;
        } else if (feature.state == 'UNDEFINED') {
          this.storeService.absence += 1;
        }

        feature.state = 'ABSENCE';
        layer.setStyle(this.storeService.absenceStyle);
        this.storeService.computeNoVisitedMeshes();
        this.updatedMeshes[feature.id] = false;
      },

      dblclick: () => {
        if (feature.state == 'PRESENCE') {
          this.storeService.presence -= 1;
        } else if (feature.state == 'ABSENCE') {
          this.storeService.absence -= 1;
        }

        feature.state = 'UNDEFINED';
        layer.setStyle(this.storeService.originStyle);
        this.storeService.computeNoVisitedMeshes();
        this.updatedMeshes[feature.id] = null;
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

  onHelp(content) {
    this.modalService.open(content);
  }

  onCancel() {
    this.router.navigate([`${ModuleConfig.MODULE_URL}/sites`, this.idSite]);
  }

  onSave() {
    const formData = Object.assign({}, this.visitForm.value);
    formData['id_base_site'] = this.idSite;
    formData['visit_date_min'] = this.dateParser.format(
      this.visitForm.controls.visit_date_min.value
    );
    formData['visit_date_max'] = this.dateParser.format(
      this.visitForm.controls.visit_date_min.value
    );
    formData['cor_visit_grid'] = this.getUpdatedVisitGrid();
    formData['cor_visit_observer'] = formData['cor_visit_observer'].map(obs => obs.id_role);
    formData['cor_visit_perturbation'] = this.cleanFormDataPerturbations(
      formData['cor_visit_perturbation']
    );
    formData['comments'] = this.visitForm.controls.comments.value;
    this.sendFormData(formData);
  }

  private getUpdatedVisitGrid() {
    // TODO: the loop below needs to be simplified
    for (let key in this.updatedMeshes) {
      let idAreaUpdated = Number(key);
      let needToInsert = true;
      let needToDelete = false;
      this.visitGrid.forEach(existingGrid => {
        if (existingGrid.id_area == idAreaUpdated) {
          needToInsert = false;
          if (this.updatedMeshes[key] !== null) {
            existingGrid.presence = this.updatedMeshes[key];
          } else {
            needToDelete = true;
          }
        }
      });
      if (needToInsert) {
        this.visitGrid.push({
          id_base_visit: Number(this.idVisit),
          presence: this.updatedMeshes[key],
          id_area: Number(key),
        });
      } else if (needToDelete) {
        this.visitGrid = this.visitGrid.filter(item => item.id_area != idAreaUpdated);
      }
    }
    return this.visitGrid;
  }

  private cleanFormDataPerturbations(perturbations) {
    let output = [];
    if (perturbations !== null && perturbations !== undefined) {
      output = perturbations.map(perturbation => perturbation.id_nomenclature);
    }
    return output;
  }

  private sendFormData(formData) {
    // Disable submit button after post
    this.disabledAfterPost = true;

    if (this.updateMode) {
      this.api.updateVisit(this.idVisit, formData).subscribe(
        result => this.onDataSavedSuccess(result),
        error => this.onDataSavedError(error)
      );
    } else {
      this.api.addVisit(formData).subscribe(
        result => this.onDataSavedSuccess(result),
        error => this.onDataSavedError(error)
      );
    }
  }

  private onDataSavedSuccess(result) {
    this.toastr.success('Visite enregistrée', '', {
      positionClass: 'toast-top-center',
    });

    this.router.navigate([`${ModuleConfig.MODULE_URL}/sites`, this.idSite]);
  }

  private onDataSavedError(error) {
    if (error.status === 403) {
      if (error.error.description.startsWith('PostYearError')) {
        const title = 'Une visite existe déjà sur ce site pour cette année !';
        const msg = this.updateMode
          ? "Veuiller corriger l'année de la date de cette visite."
          : "Veuillez plutôt éditer l'ancienne visite.";
        const options = {
          positionClass: 'toast-top-center',
          timeOut: 5000,
        };
        this.toastr.warning(msg, title, options);
      } else {
        this.commonService.translateToaster('error', 'NotAllowed');
      }
    } else {
      this.commonService.translateToaster('error', 'ErrorMessage');
    }
  }
}
