import { HttpParams } from "@angular/common/http";
import { Injectable } from "@angular/core";
import { NgbModal } from "@ng-bootstrap/ng-bootstrap";
import { Layer } from "leaflet";
import { AppConfig } from "@geonature_config/app.config";
import { ModuleConfig } from "../module.config";

@Injectable()
export class StoreService {
  public currentLayer: Layer;

  public sftConfig = ModuleConfig;

  public myStylePresent = {
    color: "#008000",
    fill: true,
    fillOpacity: 0.2,
    weight: 3
  };

  public myStyleAbsent = {
    color: "#8B0000",
    fill: true,
    fillOpacity: 0.2,
    weight: 3
  };

  public presence = 0;
  public absence = 0;
  public total = 0;
  public rest = 0;
  public urlLoad = `${AppConfig.API_ENDPOINT}/${
    ModuleConfig.MODULE_URL
  }/export_visit`;
  public queryString = new HttpParams();

  constructor(private _modalService: NgbModal) {}

  getMailleNoVisit() {
    this.rest = this.total - this.absence - this.presence;
  }

  openModal(content) {
    this._modalService.open(content);
  }
}
