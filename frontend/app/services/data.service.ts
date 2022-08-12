import { Injectable } from "@angular/core";
import { HttpClient, HttpParams } from "@angular/common/http";
import { AppConfig } from "@geonature_config/app.config";
import { ModuleConfig } from "../module.config";

@Injectable()
export class DataService {
  constructor(private _http: HttpClient) {}

  getZp(wsParams) {
    return this._http.get<any>(
      `${AppConfig.API_ENDPOINT}/${ModuleConfig.MODULE_URL}/sites`,
      {
        params: wsParams
      }
    );
  }

  getMaille(id_base_site: number, params?: any) {
    let wsParams = new HttpParams();

    for (let key in params) {
      wsParams = wsParams.set(key, params[key]);
    }
    return this._http.get<any>(
      `${AppConfig.API_ENDPOINT}/gn_monitoring/siteareas/${id_base_site}`,
      { params: wsParams }
    );
  }

  getInfoSite(id_base_site) {
    return this._http.get<any>(
      `${AppConfig.API_ENDPOINT}/${
        ModuleConfig.MODULE_URL
      }/site?id_base_site=${id_base_site}`
    );
  }

  postVisit(data: any) {
    return this._http.post<any>(
      `${AppConfig.API_ENDPOINT}/${ModuleConfig.MODULE_URL}/visit`,
      data
    );
  }

  getVisits(params: any) {
    let wsParams = new HttpParams();

    for (let key in params) {
      wsParams = wsParams.set(key, params[key]);
    }

    return this._http.get<any>(
      `${AppConfig.API_ENDPOINT}/${ModuleConfig.MODULE_URL}/visits`,
      {
        params: wsParams
      }
    );
  }

  getOneVisit(id_visit) {
    return this._http.get<any>(
      `${AppConfig.API_ENDPOINT}/${ModuleConfig.MODULE_URL}/visit/${id_visit}`
    );
  }

  getOrganisme() {
    return this._http.get<any>(
      `${AppConfig.API_ENDPOINT}/${ModuleConfig.MODULE_URL}/organisme`
    );
  }

  getCommune(id_application: string, params: any) {
    let wsParams = new HttpParams();

    for (let key in params) {
      wsParams = wsParams.set(key, params[key]);
    }

    return this._http.get<any>(
      `${AppConfig.API_ENDPOINT}/${
        ModuleConfig.MODULE_URL
      }/commune/${id_application}`,
      { params: wsParams }
    );
  }
}
