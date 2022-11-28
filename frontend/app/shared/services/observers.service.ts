import { Injectable } from '@angular/core';

import { Observer } from '../models/observer';

@Injectable({
  providedIn: 'root',
})
export class ObserversService {
  private readonly MAX_NAMES: number = 1;

  private observers: Observer[];
  private fullNames: string[];
  private abbrNames: string[];

  constructor() {
    this.initialize();
  }

  initialize() {
    this.observers = [];
    this.fullNames = [];
    this.abbrNames = [];
    return this;
  }

  addObservers(rawObservers: any[]): this {
    if (rawObservers === undefined) {
      return this;
    }
    rawObservers.forEach(rawObserver => {
      this.observers.push({
        firstname: rawObserver.prenom_role,
        lastname: rawObserver.nom_role,
      });
    });
    this.buildFullNames();
    this.buildAbbrNames();
    return this;
  }

  getObserversFull(): string {
    let names = '⚠ Aucun';
    if (this.fullNames.length > 0) {
      names = this.fullNames.join(', ') + '.';
      names = names.replace(/, ([^,]+)$/, ' & $1');
    }
    return names;
  }

  getObserversAbbr(): string {
    let abbr = '⚠ Aucun';
    if (this.abbrNames.length > 0) {
      abbr = this.abbrNames.join(', ');
    }
    if (this.abbrNames.length > this.MAX_NAMES) {
      let firstAbbrlNames = this.abbrNames.slice(0, this.MAX_NAMES);
      abbr = firstAbbrlNames.join(', ') + ' ' + this.getMore();
    }
    return abbr;
  }

  private getMore() {
    let number = this.fullNames.length - this.MAX_NAMES;
    return number > 0 ? `(+${number})` : '';
  }

  private buildFullNames() {
    this.observers.forEach(observer => {
      let fullName = observer.firstname + ' ' + observer.lastname;
      if (this.fullNames.indexOf(fullName) === -1) {
        this.fullNames.push(fullName);
      }
    });
  }

  private buildAbbrNames() {
    this.observers.forEach(observer => {
      let abbrFirstName = this.abbreviateName(observer.firstname);
      let abbrName = abbrFirstName + ' ' + observer.lastname;
      if (this.abbrNames.indexOf(abbrName) === -1) {
        this.abbrNames.push(abbrName);
      }
    });
  }

  private abbreviateName(name: string): string {
    let parts = name.split('-');
    let firtsChars = [];
    parts.forEach(part => {
      firtsChars.push(part.charAt(0));
    });
    return firtsChars.join('-') + '.';
  }
}
