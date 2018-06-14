import { Injectable, Inject } from "@angular/core";
import { HttpClient, HttpParams } from "@angular/common/http";
import { AppConfig } from "@geonature_config/app.config";

@Injectable()
export class DataService {
  constructor(private _http: HttpClient) {}

  getZp() {
    return this._http.get<any>(
      `${AppConfig.API_ENDPOINT}/suivi_flore_territoire/sites`
    );
  }
}
