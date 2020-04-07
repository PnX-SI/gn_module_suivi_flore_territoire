import { HttpParams } from "@angular/common/http";
import { Injectable } from "@angular/core";
import { NgbModal } from "@ng-bootstrap/ng-bootstrap";
import { Layer } from "leaflet";
import { AppConfig } from "@geonature_config/app.config";
import { ModuleConfig } from "../module.config";

@Injectable()
export class StoreService {
  public currentLayer: Layer;
  public sftConfig;
  public myStylePresent;
  public myStyleAbsent;
  public presence;
  public absence;
  public total;
  public rest;
  public urlLoad = `${AppConfig.API_ENDPOINT}/${ModuleConfig.MODULE_URL}/export_visit`;
  public queryString;

  constructor(private _modalService: NgbModal) {
    this.initialize();
  }

  initialize() {
    this.initializeQueryString();
    this.defineMeshesStyle();
    this.initialzeMeshesCounters();
    this.initializeModuleConfig();
  }

  private initializeQueryString() {
    this.queryString = new HttpParams();
  }

  private defineMeshesStyle() {
    this.myStylePresent = {
      color: "#008000",
      fill: true,
      fillOpacity: 0.2,
      weight: 3
    };

    this.myStyleAbsent = {
      color: "#8B0000",
      fill: true,
      fillOpacity: 0.2,
      weight: 3
    };
  }

  private initialzeMeshesCounters() {
    this.presence = 0;
    this.absence = 0;
    this.rest = 0;
    this.total = 0;
  }

  private initializeModuleConfig() {
    this.sftConfig = ModuleConfig;
  }

  getMailleNoVisit() {
    this.rest = this.total - this.absence - this.presence;
  }

  openModal(content) {
    this._modalService.open(content);
  }
}
