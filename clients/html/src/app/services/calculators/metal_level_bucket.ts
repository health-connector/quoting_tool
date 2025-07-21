import { RosterEntry } from '../../data/sponsor_roster';
import { Product } from '../../data/products';
import { Quote } from '../../data/quotes';

class CostResult {
  constructor(public family: RosterEntry, public total: number) {}
}

export class MetalLevelBucket {
  private expensiveFamilies: Map<string, CostResult> = new Map<string, CostResult>();
  private cheapFamilies: Map<string, CostResult> = new Map<string, CostResult>();

  constructor() {}

  add(product: Product, re: RosterEntry, total: number): void {
    if (this.expensiveFamilies.has(product.metal_level)) {
      const currentCostResult = this.expensiveFamilies.get(product.metal_level);
      if (currentCostResult.total < total) {
        this.expensiveFamilies.set(product.metal_level, new CostResult(re, total));
      }
    } else {
      this.expensiveFamilies.set(product.metal_level, new CostResult(re, total));
    }
    if (this.cheapFamilies.has(product.metal_level)) {
      const currentCostResult = this.cheapFamilies.get(product.metal_level);
      if (currentCostResult.total > total) {
        this.cheapFamilies.set(product.metal_level, new CostResult(re, total));
      }
    } else {
      this.cheapFamilies.set(product.metal_level, new CostResult(re, total));
    }
  }

  cheapestFor(q: Quote): CostResult | null {
    if (this.cheapFamilies.has(q.product_information.metal_level)) {
      return this.cheapFamilies.get(q.product_information.metal_level);
    }
    return null;
  }

  mostExpensiveFor(q: Quote): CostResult | null {
    if (this.expensiveFamilies.has(q.product_information.metal_level)) {
      return this.expensiveFamilies.get(q.product_information.metal_level);
    }
    return null;
  }
}
