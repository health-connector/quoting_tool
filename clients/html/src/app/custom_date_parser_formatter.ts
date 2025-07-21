import { Injectable } from '@angular/core';
import { NgbDateParserFormatter, NgbDateStruct } from '@ng-bootstrap/ng-bootstrap';

function padNumber(value: number) {
  if (isNumber(value)) {
    return `0${value}`.slice(-2);
  } else {
    return '';
  }
}

function isNumber(value: unknown): boolean {
  return !isNaN(toInteger(value));
}

function toInteger(value: unknown): number {
  return parseInt(`${value}`, 10);
}

function toYear(value: unknown): number {
  const year_digits = String(value).substring(0, 4).length;
  const birth_year = toInteger(value);
  const current_year = new Date().getFullYear();

  if (year_digits === 4 && birth_year > current_year - 120 && birth_year < current_year + 1) {
    return birth_year;
  } else {
    return null;
  }
}

@Injectable()
export class CustomDateParserFormatter extends NgbDateParserFormatter {
  parse(value: string): NgbDateStruct {
    if (value) {
      const dateParts = value.replace(/\s/g, '').trim().split('/');
      if (dateParts.length === 1 && isNumber(dateParts[0])) {
        return { year: null, month: toInteger(dateParts[0]), day: null };
      } else if (dateParts.length === 2 && isNumber(dateParts[0]) && isNumber(dateParts[1])) {
        return { year: null, month: toInteger(dateParts[0]), day: toInteger(dateParts[1]) };
      } else if (dateParts.length === 3 && isNumber(dateParts[0]) && isNumber(dateParts[1]) && isNumber(dateParts[2])) {
        return { year: toYear(dateParts[2]), month: toInteger(dateParts[0]), day: toInteger(dateParts[1]) };
      }
    }
    return null;
  }

  format(date: NgbDateStruct): string {
    let stringDate = '';
    if (date) {
      stringDate += isNumber(date.month) ? padNumber(date.month) + '/' : '';
      stringDate += isNumber(date.day) ? padNumber(date.day) + '/' : '';
      stringDate += date.year;
    }
    return stringDate;
  }
}
