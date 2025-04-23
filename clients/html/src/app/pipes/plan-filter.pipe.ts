import { Pipe, PipeTransform } from '@angular/core';

@Pipe({
  name: 'planFilter',
})
export class PlanFilterPipe implements PipeTransform {
  transform(value: boolean | null | undefined): string {
    if (value === true) {
      return 'Yes';
    } else {
      return 'No';
    }
  }
}
