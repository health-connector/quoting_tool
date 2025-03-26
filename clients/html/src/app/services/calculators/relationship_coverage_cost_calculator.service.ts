import { RelationshipContributionModel } from '../../data/contribution_models';
import { PackageTypes } from '../../config/package_types';
import { ContributionRelationship } from '../../config/contribution_relationship';
import { ContributionTierName } from '../../config/contribution_tier_name';
import { RosterEntry, RosterDependent } from '../../data/sponsor_roster';
import { Product } from '../../data/products';
import { Quote, ContributionTierCost } from '../../data/quotes';
import { ResultTotal } from './result_total';
import { MetalLevelBucket } from './metal_level_bucket';
import { IssuerBucket } from './issuer_bucket';
import { RosterQuote } from './roster_quote';
import { RelationshipDiscounts } from '../../config/relationship_discount';

class FilteredRelationshipRosterEntry {
  dob: Date;
  roster_dependents: Array<RosterDependent>;
  will_enroll: boolean;
  start_date: Date;

  constructor(
    start_date: Date,
    rel_map: Map<ContributionRelationship, boolean>,
    dob: Date,
    deps: Array<RosterDependent>,
    will_enroll: boolean
  ) {
    this.dob = dob;
    this.will_enroll = will_enroll;
    this.roster_dependents = this.filterDependents(start_date, deps, rel_map);
  }

  private coverageAge(coverageDate: Date, dob: Date) {
    const year_diff = coverageDate.getFullYear() - dob.getFullYear();
    let offset = 0;
    if (dob.getMonth() > coverageDate.getMonth()) {
      offset = -1;
    } else if (dob.getMonth() === coverageDate.getMonth()) {
      offset = dob.getDate() > coverageDate.getDate() ? -1 : 0;
    }
    return year_diff + offset;
  }

  private filterDependents(
    start_date: Date,
    deps: Array<RosterDependent>,
    rel_map: Map<ContributionRelationship, boolean>
  ) {
    return deps.filter((rd) => {
      if (rd.relationship === ContributionRelationship.CHILD) {
        const age = this.coverageAge(start_date, rd.dob);
        if (age > 26) {
          return false;
        }
        return true;
      }
      if (rel_map.has(rd.relationship)) {
        return rel_map.get(rd.relationship);
      }
      return false;
    });
  }
}

export class RelationshipCoverageCostCalculatorService {
  private startDate: Date;
  private participation: string;
  private groupSize: string;
  private filteredRoster: Array<RosterEntry>;
  private relContributions: Map<ContributionRelationship, number>;
  private minMemberCost = 0.0;
  private maxMemberCost = 0.0;

  private metalLevelBucket: MetalLevelBucket = new MetalLevelBucket();
  private issuerBucket: IssuerBucket = new IssuerBucket();
  private currentPackageKind: PackageTypes | null = null;
  private kind: string;

  constructor(
    startDate: Date,
    contributionModel: RelationshipContributionModel,
    roster: Array<RosterEntry>,
    kind: string
  ) {
    this.startDate = startDate;
    this.groupSize = this.calculateGroupSize(roster);
    this.participation = this.calculateParticipation(roster);
    this.filteredRoster = this.filterRoster(startDate, contributionModel, roster);
    const relCMap = new Map<ContributionRelationship, number>();
    contributionModel.levels.forEach(function(cl) {
      relCMap.set(cl.name, cl.contribution);
    });
    this.relContributions = relCMap;
    this.kind = kind;
  }

  private calculateParticipation(roster: Array<RosterEntry>) {
    const will_enroll = roster.filter(function(re) {
      return re.will_enroll;
    });
    const percentage = (will_enroll.length / roster.length) * 100.0;
    return Math.round(percentage).toString();
  }

  private calculateGroupSize(roster: Array<RosterEntry>) {
    const will_enroll = roster.filter(function(re) {
      return re.will_enroll;
    });
    if (will_enroll.length < 1) {
      return '1';
    }
    return Math.round(will_enroll.length).toString();
  }

  private relationshipOfferedMap(contributionModel: RelationshipContributionModel) {
    const rel_map = new Map<ContributionRelationship, boolean>();
    contributionModel.levels.forEach(function(cl) {
      rel_map.set(cl.name, cl.offered);
    });
    return rel_map;
  }

  private filterRoster(start_d: Date, contributionModel: RelationshipContributionModel, roster: Array<RosterEntry>) {
    const rel_map = this.relationshipOfferedMap(contributionModel);
    return roster
      .filter((re) => re.will_enroll)
      .map(function(re) {
        const filteredMember = new FilteredRelationshipRosterEntry(
          start_d,
          rel_map,
          re.dob,
          re.roster_dependents,
          re.will_enroll
        );
        return filteredMember;
      });
  }

  public quoteProducts(products: Array<Product>, pType: PackageTypes): Array<Quote> {
    this.currentPackageKind = pType;
    if (this.currentPackageKind === PackageTypes.METAL_LEVEL) {
      this.metalLevelBucket = new MetalLevelBucket();
    } else if (this.currentPackageKind === PackageTypes.SINGLE_ISSUER) {
      this.issuerBucket = new IssuerBucket();
    }
    const calculator = this;
    const calculated_products = products.map(function(prod) {
      return calculator.calculateQuote(prod);
    });
    if (this.currentPackageKind === PackageTypes.METAL_LEVEL) {
      const mlb = this.metalLevelBucket;
      calculated_products.forEach(function(q) {
        const cheapest = mlb.cheapestFor(q);
        if (cheapest != null) {
          q.minimum_member_cost = calculator.reducedMemberCost(q, cheapest.family, cheapest.total);
        }
        const mostExpensive = mlb.mostExpensiveFor(q);
        if (mostExpensive != null) {
          q.maximum_member_cost = calculator.reducedMemberCost(q, mostExpensive.family, mostExpensive.total);
        }
      });
    } else if (this.currentPackageKind === PackageTypes.SINGLE_ISSUER) {
      const ilb = this.issuerBucket;
      calculated_products.forEach(function(q) {
        const cheapest = ilb.cheapestFor(q);
        if (cheapest != null) {
          q.minimum_member_cost = calculator.reducedMemberCost(q, cheapest.family, cheapest.total);
        }
        const mostExpensive = ilb.mostExpensiveFor(q);
        if (mostExpensive != null) {
          q.maximum_member_cost = calculator.reducedMemberCost(q, mostExpensive.family, mostExpensive.total);
        }
      });
    }
    return calculated_products;
  }

  public reducedMemberCost(q, roster_entry, total) {
    const gs_factor = q.product_information.group_size_factor(this.groupSize);
    const pr_factor = q.product_information.participation_factor(this.participation);
    const sic_code_factor = q.product_information.sic_code_factor;
    const rt = this.resultTotalFor(q.product_information, roster_entry, sic_code_factor, gs_factor, pr_factor);
    if (rt.sponsor_cost > total) {
      return 0.0;
    }
    return total - rt.sponsor_cost;
  }

  public calculateQuote(product: Product): Quote {
    this.maxMemberCost = 0.0;
    this.minMemberCost = 100000000.0;
    const total = this.product_cost(product);
    const avg_member_cost = (total.total_cost - total.sponsor_cost) / parseFloat(this.groupSize);
    if (this.minMemberCost === 100000000.0) {
      this.minMemberCost = 0.0;
    }
    const emptyTierMap = new Map<ContributionTierName, ContributionTierCost>();
    return new RosterQuote(
      product,
      total.total_cost,
      total.sponsor_cost,
      avg_member_cost,
      this.minMemberCost,
      this.maxMemberCost,
      emptyTierMap
    );
  }

  private product_cost(product: Product) {
    const gs_factor = product.group_size_factor('1');
    const pr_factor = product.participation_factor(this.participation);
    const sic_code_factor = product.sic_code_factor;
    const calculator = this;
    const total = this.filteredRoster.reduce(function(current_total, re) {
      return current_total.add(calculator.group_cost(product, re, sic_code_factor, gs_factor, pr_factor));
    }, new ResultTotal(0.0, 0.0));
    return total;
  }

  private group_cost(
    product: Product,
    roster_entry: RosterEntry,
    sic_factor: number,
    gs_factor: number,
    pr_factor: number
  ) {
    const total = this.resultTotalFor(product, roster_entry, sic_factor, gs_factor, pr_factor);
    const memberCost = total.total_cost - total.sponsor_cost;
    if (memberCost < this.minMemberCost) {
      this.minMemberCost = memberCost;
    }
    if (memberCost > this.maxMemberCost) {
      this.maxMemberCost = memberCost;
    }
    if (this.currentPackageKind === PackageTypes.METAL_LEVEL) {
      this.metalLevelBucket.add(product, roster_entry, total.total_cost);
    }
    if (this.currentPackageKind === PackageTypes.SINGLE_ISSUER) {
      this.issuerBucket.add(product, roster_entry, total.total_cost);
    }
    return total;
  }

  private resultTotalFor(
    product: Product,
    roster_entry: RosterEntry,
    sic_factor: number,
    gs_factor: number,
    pr_factor: number
  ) {
    const subscriber_cost =
      product.cost(this.coverageAge(this.startDate, roster_entry.dob).toFixed(0)) * sic_factor * gs_factor * pr_factor;
    const subscriber_sponsor_cost = subscriber_cost * (this.relContributions.get(ContributionRelationship.SELF) * 0.01);
    const calculator = this;
    let members_in_threshold = 0;
    const sorted_dependents = roster_entry.roster_dependents.sort(function(a, b) {
      const a_age = calculator.coverageAge(calculator.startDate, a.dob);
      const b_age = calculator.coverageAge(calculator.startDate, b.dob);
      return b_age - a_age;
    });
    const total = sorted_dependents.reduce(function(current_total, rd) {
      const age = calculator.coverageAge(calculator.startDate, rd.dob);
      let dependent_cost = product.cost(age.toFixed(0)) * sic_factor * gs_factor * pr_factor;
      if (calculator.kind === 'health' && RelationshipDiscounts.relationship_discount) {
        if (
          age < RelationshipDiscounts.relationship_discount.relationship_threshold_age &&
          rd.relationship === RelationshipDiscounts.relationship_discount.relationship_kind
        ) {
          members_in_threshold = members_in_threshold + 1;
          if (members_in_threshold >= RelationshipDiscounts.relationship_discount.relationship_threshold) {
            dependent_cost = 0.0;
          }
        }
      }
      const dependent_sponsor_cost = dependent_cost * (calculator.relContributions.get(rd.relationship) * 0.01);
      const dependent_total = new ResultTotal(dependent_cost, dependent_sponsor_cost);
      return current_total.add(dependent_total);
    }, new ResultTotal(subscriber_cost, subscriber_sponsor_cost));
    return total;
  }

  private coverageAge(coverageDate: Date, dob: Date) {
    const year_diff = coverageDate.getFullYear() - dob.getFullYear();
    let offset = 0;
    if (dob.getMonth() > coverageDate.getMonth()) {
      offset = -1;
    } else if (dob.getMonth() === coverageDate.getMonth()) {
      offset = dob.getDate() > coverageDate.getDate() ? -1 : 0;
    }
    return year_diff + offset;
  }
}
