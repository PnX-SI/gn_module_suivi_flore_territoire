import { HttpParams } from '@angular/common/http';
import { Injectable } from '@angular/core';

@Injectable()
export class StoreService {
  public presenceStyle;
  public absenceStyle;
  public originStyle;
  public presence;
  public absence;
  public total;
  public rest;

  public queryString = new HttpParams();

  constructor() {
    this.initialize();
  }

  initialize() {
    this.defineMeshesStyle();
    this.initialzeMeshesCounters();
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

  computeNoVisitedMeshes() {
    this.rest = this.total - this.absence - this.presence;
  }

  loadQueryString() {
    this.queryString = new HttpParams({
      fromString: localStorage.getItem('mft-filters-querystring'),
    });
  }

  saveQueryString() {
    localStorage.setItem('mft-filters-querystring', this.queryString.toString());
  }

  clearQueryString() {
    let filterkey = this.queryString.keys();
    filterkey.forEach(key => {
      this.queryString = this.queryString.delete(key);
    });
  }
}
