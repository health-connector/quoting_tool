import { Product, ProductData } from '../data/products';
import { PackageTypes } from '../config/package_types';
import { ContributionTierName } from '../config/contribution_tier_name';

interface LoadedProductList {
  [key: number]: ProductData;
}

class LoadedProduct {
  group_size_factors: Map<string, number>;
  participation_factors: Map<string, number>;
  rates: Map<string, number>;

  constructor(
    public name: string,
    public max_group_size: number,
    group_size_factors: Map<string, number>,
    participation_factors: Map<string, number>,
    public sic_code_factor: number,
    rates: Map<string, number>,
    public min_age: number,
    public max_age: number,
    public package_kinds: Array<PackageTypes>,
    public provider_name: string,
    public metal_level: string,
    public product_type: string,
    public integrated_drug_deductible: boolean,
    public hsa_eligible: boolean,
    public hospital_stay: number,
    public emergency_stay: number,
    public pcp_office_visit: number,
    public rx: number,
    public basic_dental_services: string,
    public major_dental_services: string,
    public preventive_dental_services: string,
    public out_of_pocket_in_network: string,
    public id: string,
    public network: string,
    public deductible: number,
    public group_deductible: string,
    private tier_factors: Map<ContributionTierName, number>
  ) {
    this.group_size_factors = group_size_factors;
    this.participation_factors = participation_factors;
    this.rates = rates;
  }

  public group_tier_factor(tier_name: ContributionTierName): number {
    if (this.tier_factors.has(tier_name)) {
      return this.tier_factors.get(tier_name);
    }
    return 1.0;
  }

  public group_size_factor(group_size: string): number {
    const gs_int = parseInt(group_size, 0);
    if (gs_int > this.max_group_size) {
      return this.group_size_factors.get(this.max_group_size.toFixed(0));
    }
    return this.group_size_factors.get(group_size);
  }

  public participation_factor(participation: string): number {
    return this.participation_factors.get(participation);
  }

  public cost(age: string): number {
    const age_int = parseInt(age, 0);
    if (age_int > this.max_age) {
      return this.getRate(this.max_age.toFixed(0));
    } else if (age_int < this.min_age) {
      return this.getRate(this.min_age.toFixed(0));
    }
    return this.getRate(age);
  }

  private getRate(age: string) {
    return this.rates.get(age);
  }
}

export class ProductDataLoader {
  public load(raw_data: string): Array<Product> {
    const data: Array<ProductData> | null = <Array<ProductData>>JSON.parse(raw_data);
    if (data != null) {
      return this.castData(data);
    }
    return [];
  }

  public castJSON(parsed_data: any) {
    const data: LoadedProductList | null = <LoadedProductList>parsed_data;
    if (data != null) {
      const products = [];
      const caster = this;
      Object.keys(data).forEach(function(k) {
        if (k !== 'default') {
          products.push(caster.castSingleProduct(data[k]));
        }
      });
      return products;
    }
    return [];
  }

  public castData(data: Array<ProductData>): Array<Product> {
    return data.map(this.castSingleProduct);
  }

  private castSingleProduct(data: ProductData): Product {
    const participation_factors = new Map<string, number>();
    const group_size_factors = new Map<string, number>();
    const rates = new Map<string, number>();
    Object.keys(data.participation_factors).forEach(function(k) {
      participation_factors.set(k, data.participation_factors[k]);
    });
    Object.keys(data.group_size_factors.factors).forEach(function(k) {
      group_size_factors.set(k, data.group_size_factors.factors[k]);
    });
    Object.keys(data.rates.entries).forEach(function(k) {
      rates.set(k, data.rates.entries[k]);
    });
    const product_tfs = new Map<ContributionTierName, number>();
    if (data.group_tier_factors != null) {
      data.group_tier_factors.forEach(function(gtf) {
        product_tfs.set(gtf.name, gtf.factor);
      });
    }
    return new LoadedProduct(
      data.name,
      data.group_size_factors.max_group_size,
      group_size_factors,
      participation_factors,
      data.sic_code_factor,
      rates,
      data.rates.min_age,
      data.rates.max_age,
      <Array<PackageTypes>>data.available_packages,
      data.provider_name,
      data.metal_level,
      data.product_type,
      data.integrated_drug_deductible,
      data.hsa_eligible,
      data.hospital_stay,
      data.emergency_stay,
      data.pcp_office_visit,
      data.rx,
      data.basic_dental_services,
      data.major_dental_services,
      data.preventive_dental_services,
      data.out_of_pocket_in_network,
      data.id,
      data.network,
      data.deductible,
      data.group_deductible,
      product_tfs
    );
  }
}
