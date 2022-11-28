import { HttpParams } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { NgbModal } from '@ng-bootstrap/ng-bootstrap';
import { Layer } from 'leaflet';
import { AppConfig } from '@geonature_config/app.config';
import { ModuleConfig } from '../module.config';

@Injectable()
export class StoreService {
  public currentLayer: Layer;
  public sftConfig;
  public presenceStyle;
  public absenceStyle;
  public originStyle;
  public presence;
  public absence;
  public total;
  public rest;
  public urlLoad = `${AppConfig.API_ENDPOINT}/${ModuleConfig.MODULE_URL}/visits/export`;
  public queryString = new HttpParams();

  constructor(private _modalService: NgbModal) {
    this.initialize();
  }

  initialize() {
    this.defineMeshesStyle();
    this.initialzeMeshesCounters();
    this.initializeModuleConfig();
  }

  private defineMeshesStyle() {
    this.presenceStyle = {
      color: '#008000',
      fill: true,
      fillOpacity: 0.2,
      weight: 3,
    };

    this.absenceStyle = {
      color: '#8B0000',
      fill: true,
      fillOpacity: 0.2,
      weight: 3,
    };

    this.originStyle = {
      color: '#3388ff',
      fill: true,
      fillOpacity: 0.2,
      weight: 3,
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

  computeNoVisitedMeshes() {
    this.rest = this.total - this.absence - this.presence;
  }

  openModal(content) {
    this._modalService.open(content);
  }

  loadQueryString() {
    this.queryString = new HttpParams({
      fromString: localStorage.getItem('sft-filters-querystring'),
    });
  }

  saveQueryString() {
    localStorage.setItem('sft-filters-querystring', this.queryString.toString());
  }

  clearQueryString() {
    let filterkey = this.queryString.keys();
    filterkey.forEach(key => {
      this.queryString = this.queryString.delete(key);
    });
  }
}
