import { Pipe, PipeTransform } from '@angular/core';

@Pipe({
    name: 'orderBy',
    standalone: true
})
export class OrderByPipe implements PipeTransform {

  transform(value: any, ...args: any[]): any {
    if (args[0] === 'asc' && !args[3]) {
      return value.sort((a, b) => parseFloat(a.sponsor_cost) - parseFloat(b.sponsor_cost));
    } else if (args[0] === 'desc' && args[3] && args[3][0].includes('Employer Cost')) {
      return value.sort((a, b) => parseFloat(b.sponsor_cost) - parseFloat(a.sponsor_cost));
    } else if (args[0] === 'asc' && args[3] && args[3][0].includes('Employer Cost')) {
      return value.sort((a, b) => parseFloat(a.sponsor_cost) - parseFloat(b.sponsor_cost));
    } else if (args[0] === 'asc' && args[3] && args[3][0].includes('Annual Deductible')) {
      return value.sort((a, b) => parseInt(a.deductible.replace('$', '').replace(',', ''), 0)
        - parseInt(b.deductible.replace('$', '').replace(',', ''), 0));
    } else if (args[0] === 'desc' && args[3] && args[3][0].includes('Annual Deductible')) {
      return value.sort((a, b) => parseInt(b.deductible.replace('$', '').replace(',', ''), 0)
        - parseInt(a.deductible.replace('$', '').replace(',', ''), 0));
    } else if (args[0] === 'asc' && args[3] && args[3][0].includes('Out of Pocket')) {
      return value.sort((a, b) => parseInt(a['product_information']['out_of_pocket_in_network']
          .split('|')[0].replace('per person', '').replace('$', ''), 0) -
          parseInt(b['product_information']['out_of_pocket_in_network']
            .split('|')[0].replace('per person', '').replace('$', ''), 0)
        );
    } else if (args[0] === 'desc' && args[3] && args[3][0].includes('Out of Pocket')) {
      return value.sort((a, b) => parseInt(b['product_information']['out_of_pocket_in_network']
          .split('|')[0].replace('per person', '').replace('$', ''), 0) -
          parseInt(a['product_information']['out_of_pocket_in_network']
            .split('|')[0].replace('per person', '').replace('$', ''), 0)
        );
    }
  }

}
