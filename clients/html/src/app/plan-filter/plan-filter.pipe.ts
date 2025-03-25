import { Pipe, PipeTransform } from '@angular/core';

@Pipe({
    name: 'planFilter',
    standalone: true
})
export class PlanFilterPipe implements PipeTransform {
  transform(value: any, ...args: any[]): any {
    if (value === true) {
      return 'Yes';
    } else {
      return 'No';
    }
  }
}
