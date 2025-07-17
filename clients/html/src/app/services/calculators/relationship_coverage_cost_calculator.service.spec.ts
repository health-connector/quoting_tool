import { RosterDependent } from '../../data/sponsor_roster';
import { ContributionRelationship } from '../../config/contribution_relationship';
import { RelationshipCoverageCostCalculatorService } from './relationship_coverage_cost_calculator.service';
import { defaultRelationshipContributionModel } from './../../config/client_configuration';

function createMockDependent(rel: ContributionRelationship, dob: Date): RosterDependent {
  return {
    dob: dob,
    relationship: rel,
  };
}

class MockRosterEntry {
  public dependents: Array<{ dob: string | Date; relationship: string }>;

  constructor(
    public dob: Date,
    public will_enroll: boolean,
    public roster_dependents: Array<RosterDependent>,
    public coverageKind: string,
  ) {
    this.dependents = roster_dependents.map((dep) => ({
      dob: dep.dob,
      relationship: dep.relationship.toString(),
    }));
  }
}

export function getDefaultValue<K, V>(m: Map<K, V>, k: K, default_value: V) {
  const value = <V>m.get(k);
  if (value != null) {
    return value;
  }
  return default_value;
}

class MockCalculationProduct {
  public package_kinds = [];

  constructor(
    public name: string,
    public max_group_size: number,
    public group_size_factors: Map<string, number>,
    public participation_factors: Map<string, number>,
    public sic_code_factor: number,
    private rates: Map<string, number>,
    private min_age: number,
    private max_age: number,
    public provider_name: string,
    public metal_level: string,
    public product_type: string,
    public network: string,
    public deductible: number,
    public group_deductible: string,
    public integrated_drug_deductible: boolean,
    public hsa_eligible: boolean,
    public emergency_stay: number,
    public pcp_office_visit: number,
    public rx: number,
    public hospital_stay: number,
    public preventive_dental_services: string,
    public major_dental_services: string,
    public basic_dental_services: string,
    public out_of_pocket_in_network: string,
    public id: string,
  ) {}

  public group_tier_factor(): number {
    return 1.0;
  }

  public group_size_factor(group_size: string): number {
    const gs_int = parseInt(group_size, 0);
    if (gs_int > this.max_group_size) {
      return getDefaultValue(this.group_size_factors, this.max_group_size.toFixed(0), 1.0);
    }
    return getDefaultValue(this.group_size_factors, group_size, 1.0);
  }
  public participation_factor(participation: string): number {
    return getDefaultValue(this.participation_factors, participation, 1.0);
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
    return getDefaultValue(this.rates, age, 0.0);
  }
}

describe('RelationshipCoverageCostCalculatorService, created with a roster', () => {
  const start_date = new Date(2019, 0, 1);
  const subscriber_1_dob = new Date(1999, 11, 15);

  const gs_factors = new Map<string, number>();
  gs_factors.set('1', 1.0);
  gs_factors.set('2', 1.0);

  const pr_factors = new Map<string, number>();
  pr_factors.set('100', 1);

  const rates = new Map<string, number>();
  rates.set('19', 1.0);

  const product = new MockCalculationProduct(
    'MockCalculationProduct',
    2,
    gs_factors,
    pr_factors,
    1,
    rates,
    19,
    19,
    'Carefirst',
    'silver',
    'hmo',
    'DCS0',
    1000,
    'LOTS',
    true,
    false,
    21,
    21,
    21,
    21,
    '20%',
    '20%',
    '20%',
    '20%',
    '1',
  );

  it('calculates the product quote', () => {
    const dependents = [];

    const entry_1 = new MockRosterEntry(subscriber_1_dob, true, dependents, 'health');

    const service = new RelationshipCoverageCostCalculatorService(
      start_date,
      defaultRelationshipContributionModel(),
      [entry_1],
      'health',
    );
    const quote = service.calculateQuote(product);
    expect(quote.total_cost).not.toBe(0.0);
  });

  it('should not calculate health product quote for 4th child age < 21', () => {
    const dependents = [
      createMockDependent(ContributionRelationship.CHILD, new Date()),
      createMockDependent(ContributionRelationship.CHILD, new Date()),
      createMockDependent(ContributionRelationship.CHILD, new Date()),
      createMockDependent(ContributionRelationship.CHILD, new Date()),
    ];

    const entry_1 = new MockRosterEntry(subscriber_1_dob, true, dependents, 'health');
    const service = new RelationshipCoverageCostCalculatorService(
      start_date,
      defaultRelationshipContributionModel(),
      [entry_1],
      'health',
    );
    const quote = service.calculateQuote(product);
    expect(quote.total_cost).toBe(4.0);
  });

  it('should calculate dental product quote for 4th child age < 21', () => {
    const dependents = [
      createMockDependent(ContributionRelationship.CHILD, new Date()),
      createMockDependent(ContributionRelationship.CHILD, new Date()),
      createMockDependent(ContributionRelationship.CHILD, new Date()),
      createMockDependent(ContributionRelationship.CHILD, new Date()),
    ];

    const entry_1 = new MockRosterEntry(subscriber_1_dob, true, dependents, 'dental');
    const service = new RelationshipCoverageCostCalculatorService(
      start_date,
      defaultRelationshipContributionModel(),
      [entry_1],
      'dental',
    );
    const quote = service.calculateQuote(product);
    expect(quote.total_cost).toBe(5.0);
  });
});
