import { Pipe, PipeTransform } from '@angular/core';

// Define an interface for the objects being sorted
interface SortablePlan {
  sponsor_cost: string | number;
  deductible: string;
  product_information?: {
    // Mark as optional for safety
    out_of_pocket_in_network?: string; // Mark as optional for safety
  };
}

// Helper function to safely parse currency/numeric strings (removes $, , handles potential text)
function parseNumeric(value: string | number | undefined | null): number {
  if (typeof value === 'number') return value;
  if (typeof value !== 'string') return NaN;
  // Remove $, ,, split by | take first part, trim
  const cleaned = value.replace(/[$,]/g, '').split('|')[0].trim();
  const num = parseFloat(cleaned);
  return isNaN(num) ? -Infinity : num; // Handle NaN, return -Infinity to sort them first/last consistently
}

@Pipe({
  name: 'orderBy',
  standalone: true,
})
export class OrderByPipe implements PipeTransform {
  // Type the input value and arguments more specifically
  transform(
    value: SortablePlan[] | null | undefined,
    ...args: ['asc' | 'desc', string, unknown, string[]?]
  ): SortablePlan[] {
    // Handle null or empty array input
    if (!value || value.length === 0) {
      return [];
    }

    const sortDirection = args[0];
    // const sortKey = args[1]; // Seems unused in original logic
    const headerNameArray = args[3];
    const headerName = headerNameArray?.[0]; // Get the first element if the array exists

    // Create a copy to avoid modifying the original array
    const sortedArray = [...value];

    sortedArray.sort((a, b) => {
      let comparison = 0;
      let valA: number;
      let valB: number;

      if (headerName?.includes('Employer Cost')) {
        valA = parseNumeric(a.sponsor_cost);
        valB = parseNumeric(b.sponsor_cost);
        comparison = valA - valB;
      } else if (headerName?.includes('Annual Deductible')) {
        valA = parseNumeric(a.deductible);
        valB = parseNumeric(b.deductible);
        comparison = valA - valB;
      } else if (headerName?.includes('Out of Pocket')) {
        valA = parseNumeric(a.product_information?.out_of_pocket_in_network);
        valB = parseNumeric(b.product_information?.out_of_pocket_in_network);
        comparison = valA - valB;
      }
      // Default: maintain original order if headerName doesn't match known patterns

      // Apply sort direction (handles NaN comparison implicitly via subtraction)
      return sortDirection === 'asc' ? comparison : -comparison;
    });

    return sortedArray;
  }
}
