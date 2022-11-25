import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { AppConfig } from '@geonature_config/app.config';
import { ModuleConfig } from '../module.config';

@Injectable()
export class DataService {
  apiGn: string = AppConfig.API_ENDPOINT;
  apiModule: string = `${AppConfig.API_ENDPOINT}${ModuleConfig.MODULE_URL}`;

  constructor(private _http: HttpClient) {}

  getMeshes(id_base_site: number, params?: any) {
    let wsParams = new HttpParams();

    for (let key in params) {
      wsParams = wsParams.set(key, params[key]);
    }
    return this._http.get<any>(`${this.apiGn}/gn_monitoring/siteareas/${id_base_site}`, {
      params: wsParams,
    });
  }

  getSites(wsParams) {
    return this._http.get<any>(`${this.apiModule}/sites`, { params: wsParams });
  }

  getOneSite(id_base_site) {
    return this._http.get<any>(`${this.apiModule}/sites/${id_base_site}`);
  }

  getVisits(params: any) {
    let wsParams = new HttpParams();

    for (let key in params) {
      wsParams = wsParams.set(key, params[key]);
    }

    return this._http.get<any>(`${this.apiModule}/visits`, { params: wsParams });
  }

  getOneVisit(id_visit) {
    return this._http.get<any>(`${this.apiModule}/visits/${id_visit}`);
  }

  editVisit(data: any) {
    return this._http.post<any>(`${this.apiModule}/visits`, data);
  }

  getVisitsYears() {
    return this._http.get<any>(`${this.apiModule}/visits/years`);
  }

  getOrganisms() {
    return this._http.get<any>(`${this.apiModule}/organisms`);
  }

  getMunicipalities() {
    return this._http.get<any>(`${this.apiModule}/municipalities`);
  }
}
