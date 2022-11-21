import { of } from '@librairies/rxjs';

import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';

import { AppConfig } from '@geonature_config/app.config';

import { ModuleConfig } from '../module.config';

@Injectable()
export class ConfigService {
  private config;

  constructor(private _http: HttpClient) {}

  initialize() {
    this.config = {};
    this.config['frontendParams'] = {
      bChainInput: false,
    };
    return of(true);
  }

  getModuleCode() {
    return ModuleConfig.MODULE_CODE;
  }

  getApplicationUrl() {
    return `${AppConfig.URL_APPLICATION}`;
  }

  getBackendUrl() {
    return `${AppConfig.API_ENDPOINT}`;
  }

  getBackendModuleUrl() {
    return `${AppConfig.API_ENDPOINT}/${ModuleConfig.MODULE_URL}`;
  }

  getFrontendModuleUrl() {
    return ModuleConfig.MODULE_URL;
  }

  geFrontendParams() {
    return this.config.frontendParams;
  }

  setFrontendParams(paramName, paramValue) {
    if (this.config && this.config.frontendParams) {
      this.config.frontendParams[paramName] = paramValue;
    }
  }

  getAll() {
    return this.config;
  }
}
