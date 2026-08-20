import { PackageTypes } from '../config/package_types';
import { ContributionTierName } from '../config/contribution_tier_name';

export interface RateEntry {
  age: string;
  rate: number;
}

export interface FactorData {
  [key: string]: number;
}

export interface RateData {
  max_age: number;
  min_age: number;
  entries: FactorData;
}

export interface GroupSizeFactorData {
  max_group_size: number;
  factors: FactorData;
}

export interface TierFactorEntry {
  name: ContributionTierName;
  factor: number;
}

export interface ProductData {
  name: string;
  provider_name: string;
  metal_level: string;
  product_type: string;
  deductible: number;
  group_deductible: string;
  network: string;
  integrated_drug_deductible: boolean;
  hsa_eligible: boolean;
  emergency_stay: number;
  pcp_office_visit: number;
  rx: number;
  hospital_stay: number;
  available_packages: Array<PackageTypes>;
  sic_code_factor: number;
  group_size_factors: GroupSizeFactorData;
  participation_factors: FactorData;
  group_tier_factors: Array<TierFactorEntry>;
  rates: RateData;
  preventive_dental_services: string;
  major_dental_services: string;
  basic_dental_services: string;
  out_of_pocket_in_network: string;
  id: string;
}

export interface Product {
  name: string;
  package_kinds: Array<PackageTypes>;
  sic_code_factor: number;
  provider_name: string;
  metal_level: string;
  product_type: string;
  network: string;
  deductible: number;
  group_deductible: string;
  integrated_drug_deductible: boolean;
  hsa_eligible: boolean;
  emergency_stay: number;
  pcp_office_visit: number;
  rx: number;
  hospital_stay: number;
  preventive_dental_services: string;
  major_dental_services: string;
  basic_dental_services: string;
  out_of_pocket_in_network: string;
  id: string;
  group_size_factor(group_size: string): number;
  group_tier_factor(tier_name: ContributionTierName): number;
  participation_factor(participation: string): number;
  cost(age: string): number | undefined;
}
