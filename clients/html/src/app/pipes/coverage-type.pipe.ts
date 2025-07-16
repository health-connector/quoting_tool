import { Pipe, PipeTransform } from '@angular/core';

@Pipe({
  name: 'coverageType',
})
export class CoverageTypePipe implements PipeTransform {
  transform(value: string): string {
    let name: string;
    switch (value) {
      case 'both':
        name = 'Both';
        break;
      case 'healthOnly':
        name = 'Health Only';
        break;
      case 'dentalOnly':
        name = 'Dental Only';
        break;
    }
    return name;
  }
}
