import { Component, OnInit, AfterViewInit, ViewChild } from "@angular/core";
import { Router, ActivatedRoute } from "@angular/router";

import { NgbDateParserFormatter } from "@ng-bootstrap/ng-bootstrap";
import { ToastrService } from "ngx-toastr";

import { CommonService } from "@geonature_common/service/common.service";
import { MapService } from "@geonature_common/map/map.service";
import { GeojsonComponent } from "@geonature_common/map/geojson/geojson.component";
import { DataFormService } from "@geonature_common/form/data-form.service";

import { DataService } from "../services/data.service";
import { StoreService } from "../services/store.service";
import { FormService } from "../services/form.service";
import { ModuleConfig } from "../module.config";

@Component({
  selector: "pnx-form-visit",
  templateUrl: "form-visit.component.html",
  styleUrls: ["./form-visit.component.scss"]
})
export class FormVisitComponent implements OnInit, AfterViewInit {
  public zps;

  public modifGrid;
  public nomTaxon;
  public date;
  public idVisit;
  public idSite;
  public namePertur = [];
  public visitGrid = []; // tableau de l'objet maille visité : [{id_area: qqc, presence: true/false}]
  public tabObserver = [];
  public visitModif = {}; // l'objet maille visité (modifié)
  public disabledAfterPost = false;

  @ViewChild("geojson")
  geojson: GeojsonComponent;

  constructor(
    public mapService: MapService,
    public _api: DataService,
    public activatedRoute: ActivatedRoute,
    public storeService: StoreService,
    public router: Router,
    public dataFormService: DataFormService,
    public dateParser: NgbDateParserFormatter,
    private toastr: ToastrService,
    private _commonService: CommonService,
    public formService: FormService
  ) {}

  ngOnInit() {
    this.idSite = this.activatedRoute.snapshot.params["idSite"];

    this.idVisit = this.activatedRoute.snapshot.params["idVisit"];

    this.modifGrid = this.formService.initFormSFT();
  }

  ngAfterViewInit() {
    this.mapService.map.doubleClickZoom.disable();
    // récupère nom de l'espèce

    this._api.getInfoSite(this.idSite).subscribe(info => {
      this.dataFormService.getTaxonInfo(info.cd_nom).subscribe(taxon => {
        this.nomTaxon = taxon.nom_valide;
      });
    });

    // vérifie s'il existe idVisit --> c'est une modification
    if (this.idVisit !== undefined) {
      this._api.getOneVisit(this.idVisit).subscribe(element => {
        this.visitGrid = element.cor_visit_grid;
        this.storeService.presence = 0;
        this.storeService.absence = 0;
        // compter l'absence/présence des mailles déjà existantes
        if (this.visitGrid !== undefined) {
          this.visitGrid.forEach(grid => {
            if (grid.presence == true) {
              this.storeService.presence += 1;
            } else {
              this.storeService.absence += 1;
            }
          });
        }

        let typePer;
        let tabVisitPerturb = element.cor_visit_perturbation;

        if (tabVisitPerturb !== undefined) {
          tabVisitPerturb.forEach(per => {
            if (per === tabVisitPerturb[tabVisitPerturb.length - 1]) {
              typePer = per.label_fr + ". ";
            } else {
              typePer = per.label_fr + ", ";
            }
            this.namePertur.push(typePer);
          });
        }

        this.date = element.visit_date_min;

        let fullNameObserver;

        element.observers.forEach(name => {
          if (name === element.observers[element.observers.length - 1]) {
            fullNameObserver = name.nom_complet + ". ";
          } else {
            fullNameObserver = name.nom_complet + ", ";
          }
          this.tabObserver.push(fullNameObserver);
        });

        this.modifGrid.patchValue({
          id_base_site: this.idSite,
          id_base_visit: this.idVisit,
          visit_date_min: this.dateParser.parse(this.date),
          visit_date_max: this.dateParser.parse(this.date),
          cor_visit_observer: element.observers,
          cor_visit_perturbation: element.cor_visit_perturbation,
          cor_visit_grid: this.visitGrid,
          comments: element.comments
        });
      });
    }

    this._api
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

    // évenement quand modifier statut de maille
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
        this.visitGrid.forEach(dataG => {
          if (feature.id == dataG.id_area) {
            dataG.presence = true;
          }
        });
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
        this.visitGrid.forEach(dataG => {
          if (feature.id == dataG.id_area) {
            dataG.presence = false;
          }
        });
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
        this.visitGrid.forEach(dataG => {
          if (feature.id == dataG.id_area) {
            dataG.presence = false;
          }
        });
        this.visitModif[feature.id] = false;
      }
    });
  }

  onVisual() {
    this.router.navigate([`${ModuleConfig.MODULE_URL}/listVisit`, this.idSite]);
  }

  onModif() {
    const formModif = Object.assign({}, this.modifGrid.value);

    formModif["id_base_site"] = this.idSite;
    //  formModif['visit_date_min'] = this.dateParser.format(formModif['visit_date_min']);
    formModif["visit_date_min"] = this.dateParser.format(
      this.modifGrid.controls.visit_date_min.value
    );
    formModif["visit_date_max"] = this.dateParser.format(
      this.modifGrid.controls.visit_date_min.value
    );

    for (let key in this.visitModif) {
      this.visitGrid.push({
        id_base_visit: this.idVisit,
        presence: this.visitModif[key],
        id_area: key
      });
    }

    formModif["cor_visit_grid"] = this.visitGrid;

    formModif["cor_visit_observer"] = formModif["cor_visit_observer"].map(
      obs => {
        return obs.id_role;
      }
    );

    if (
      formModif["cor_visit_perturbation"] !== null &&
      formModif["cor_visit_perturbation"] !== undefined
    ) {
      formModif["cor_visit_perturbation"] = formModif[
        "cor_visit_perturbation"
      ].map(pertu => pertu.id_nomenclature);
    }

    formModif["comments"] = this.modifGrid.controls.comments.value;

    this._api.postVisit(formModif).subscribe(
      data => {
        this.toastr.success("Visite enregistrée", "", {
          positionClass: "toast-top-center"
        });

        this.router.navigate([
          `${ModuleConfig.MODULE_URL}/listVisit`,
          this.idSite
        ]);
      },
      error => {
        if (error.status === 403) {
          if (error.error.raisedError === "PostYearError") {
            this.toastr.warning(
              "Veuillez plutôt éditer une ancienne visite ",
              "Une visite existe déjà sur ce site pour cette année !",
              {
                positionClass: "toast-top-center",
                timeOut: 5000
              }
            );
          } else {
            this._commonService.translateToaster("error", "NotAllowed");
          }
        } else {
          this._commonService.translateToaster("error", "ErrorMessage");
        }
      }
    );
    // griser le bouton après avoir posté la visite
    this.disabledAfterPost = true;
  }
}
