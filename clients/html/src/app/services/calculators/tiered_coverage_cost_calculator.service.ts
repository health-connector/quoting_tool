import { TieredContributionModel } from '../../data/contribution_models';
import { RosterEntry, RosterDependent } from '../../data/sponsor_roster';
import { ContributionRelationship } from '../../config/contribution_relationship';
import { ContributionTierName } from '../../config/contribution_tier_name';
import { Product } from '../../data/products';
import { Quote, ContributionTierCost } from '../../data/quotes';
import { ResultTotal } from './result_total';
import { RosterQuote } from './roster_quote';
import { RelationshipDiscounts } from '../../config/relationship_discount';

class FilteredRelationshipRosterEntry {
  dob: Date;
  roster_dependents: Array<RosterDependent>;
  will_enroll: boolean;
  start_date: Date;
  bucket: ContributionTierName;

  constructor(
    start_date: Date,
    rel_map: Map<ContributionTierName, boolean>,
    allowed_buckets: Array<ContributionTierName>,
    dob: Date,
    deps: Array<RosterDependent>,
    will_enroll: boolean,
  ) {
    this.dob = dob;
    this.will_enroll = will_enroll;
    this.setBucketAndDeps(start_date, deps, rel_map, allowed_buckets);
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

  private kickTooOldChildren(start_date: Date, deps: Array<RosterDependent>) {
    // Using arrow function to preserve the 'this' context
    return deps.filter((rd) => {
      if (rd.relationship === ContributionRelationship.CHILD) {
        const age = this.coverageAge(start_date, rd.dob);
        if (age > 26) {
          return false;
        }
      }
      return true;
    });
  }

  private filterDependents(
    start_date: Date,
    deps: Array<RosterDependent>,
    rel_map: Map<ContributionTierName, boolean>,
  ) {
    if (rel_map.get(ContributionTierName.FAMILY)) {
      return deps;
    }
    if (
      !(
        rel_map.get(ContributionTierName.FAMILY) ||
        rel_map.get(ContributionTierName.EMPLOYEE_AND_SPOUSE) ||
        ContributionTierName.EMPLOYEE_AND_DEPENDENTS
      )
    ) {
      return [];
    }
    let filtered_deps = deps;
    if (!rel_map.get(ContributionTierName.EMPLOYEE_AND_DEPENDENTS)) {
      filtered_deps = deps.filter((d) => {
        return d.relationship !== ContributionRelationship.CHILD;
      });
    }
    if (!rel_map.get(ContributionTierName.EMPLOYEE_AND_SPOUSE)) {
      filtered_deps = filtered_deps.filter((d) => {
        return d.relationship === ContributionRelationship.CHILD;
      });
    }
    return filtered_deps;
  }

  private setBucketAndDeps(start_date, deps, rel_map, allowed_buckets) {
    const clean_deps = this.kickTooOldChildren(start_date, deps);
    this.roster_dependents = this.filterDependents(start_date, clean_deps, rel_map);
    this.bucket = this.selectBucket(this.roster_dependents, allowed_buckets);
  }

  private selectBucket(remaining_deps, allowed_buckets: Array<ContributionTierName>) {
    if (remaining_deps.length < 1) {
      return ContributionTierName.EMPLOYEE_ONLY;
    }
    let remain_to_pick = allowed_buckets.filter((ab) => {
      return ab !== ContributionTierName.EMPLOYEE_ONLY;
    });
    if (remain_to_pick.length < 2) {
      return remain_to_pick[0];
    }
    const rels = this.remainingRelationships(remaining_deps);
    if (remain_to_pick.indexOf(ContributionTierName.EMPLOYEE_AND_SPOUSE) > -1) {
      if (
        rels.indexOf(ContributionRelationship.SPOUSE) > -1 ||
        rels.indexOf(ContributionRelationship.DOMESTIC_PARTNER) > -1
      ) {
        if (rels.indexOf(ContributionRelationship.CHILD) === -1) {
          return ContributionTierName.EMPLOYEE_AND_SPOUSE;
        }
      }
    }
    if (
      remain_to_pick.indexOf(ContributionTierName.EMPLOYEE_AND_SPOUSE) > -1 &&
      rels.indexOf(ContributionRelationship.CHILD) > -1
    ) {
      remain_to_pick = remain_to_pick.filter((ab) => {
        return ab !== ContributionTierName.EMPLOYEE_AND_SPOUSE;
      });
    }
    if (remain_to_pick.length < 2) {
      return remain_to_pick[0];
    }
    if (
      remain_to_pick.indexOf(ContributionTierName.EMPLOYEE_AND_DEPENDENTS) > -1 &&
      !(
        rels.indexOf(ContributionRelationship.SPOUSE) > -1 ||
        rels.indexOf(ContributionRelationship.DOMESTIC_PARTNER) > -1
      )
    ) {
      return ContributionTierName.EMPLOYEE_AND_DEPENDENTS;
    }
    if (remain_to_pick.length < 2) {
      return remain_to_pick[0];
    }
    return ContributionTierName.FAMILY;
  }

  private remainingRelationships(remaining_deps) {
    return remaining_deps.map((rd) => {
      return rd.relationship;
    });
  }
}

class BucketCount {
  constructor(
    public counts: Map<ContributionTierName, number>,
    public total: number,
  ) {}

  public add(entry: FilteredRelationshipRosterEntry, price: number) {
    const current_count = this.valueFromMapWithDefault(this.counts, entry.bucket, 0);
    this.counts.set(entry.bucket, current_count + 1);
    return new BucketCount(this.counts, this.total + price);
  }

  public toLevels(product) {
    let denominator = 0.0;
    this.counts.forEach((v, k) => {
      denominator = denominator + v * product.group_tier_factor(k);
    });
    const bucket_map = new Map<ContributionTierName, number>();
    const reduced_value = this.total / denominator;
    bucket_map.set(
      ContributionTierName.EMPLOYEE_ONLY,
      reduced_value * product.group_tier_factor(ContributionTierName.EMPLOYEE_ONLY),
    );
    bucket_map.set(
      ContributionTierName.EMPLOYEE_AND_SPOUSE,
      reduced_value * product.group_tier_factor(ContributionTierName.EMPLOYEE_AND_SPOUSE),
    );
    bucket_map.set(
      ContributionTierName.EMPLOYEE_AND_DEPENDENTS,
      reduced_value * product.group_tier_factor(ContributionTierName.EMPLOYEE_AND_DEPENDENTS),
    );
    bucket_map.set(ContributionTierName.FAMILY, reduced_value * product.group_tier_factor(ContributionTierName.FAMILY));
    return bucket_map;
  }

  private valueFromMapWithDefault<K, V>(m: Map<K, V>, k: K, default_value: V) {
    const value = <V>m.get(k);
    if (value != null) {
      return value;
    }
    return default_value;
  }
}

export class TieredCoverageCostCalculatorService {
  private startDate: Date;
  private participation: string;
  private groupSize: string;
  private filteredRoster: Array<FilteredRelationshipRosterEntry>;
  private relContributions: Map<ContributionTierName, number>;
  private kind: string;

  constructor(startDate: Date, contributionModel: TieredContributionModel, roster: Array<RosterEntry>, kind: string) {
    this.startDate = startDate;
    this.groupSize = this.calculateGroupSize(roster);
    this.participation = this.calculateParticipation(roster);
    this.filteredRoster = this.filterRoster(startDate, contributionModel, roster);
    const relCMap = new Map<ContributionTierName, number>();
    contributionModel.levels.forEach((cl) => {
      relCMap.set(cl.name, cl.contribution);
    });
    this.relContributions = relCMap;
    this.kind = kind;
  }

  private calculateParticipation = (roster: Array<RosterEntry>) => {
    const will_enroll = roster.filter((re) => {
      return re.will_enroll;
    });
    const percentage = (will_enroll.length / roster.length) * 100.0;
    return Math.round(percentage).toString();
  };

  private calculateGroupSize = (roster: Array<RosterEntry>) => {
    const will_enroll = roster.filter((re) => {
      return re.will_enroll;
    });
    if (will_enroll.length < 1) {
      return '1';
    }
    return Math.round(will_enroll.length).toString();
  };

  private tierOfferedMap = (contributionModel: TieredContributionModel) => {
    const rel_map = new Map<ContributionTierName, boolean>();
    contributionModel.levels.forEach((cl) => {
      rel_map.set(cl.name, cl.offered);
    });
    return rel_map;
  };

  private allowedTiers = (contributionModel: TieredContributionModel) => {
    const rel_map = new Array<ContributionTierName>();
    contributionModel.levels.forEach((cl) => {
      if (cl.offered) {
        rel_map.push(cl.name);
      }
    });
    return rel_map;
  };

  private filterRoster(start_d: Date, contributionModel: TieredContributionModel, roster: Array<RosterEntry>) {
    const rel_map = this.tierOfferedMap(contributionModel);
    const allowedTiers = this.allowedTiers(contributionModel);
    return roster
      .filter((re) => re.will_enroll)
      .map((re) => {
        const dobDate = typeof re.dob === 'string' ? new Date(re.dob) : re.dob;
        const filteredMember = new FilteredRelationshipRosterEntry(
          start_d,
          rel_map,
          allowedTiers,
          dobDate,
          re.roster_dependents,
          re.will_enroll,
        );
        return filteredMember;
      });
  }

  public quoteProducts(products: Array<Product>): Array<Quote> {
    return products.map((prod) => {
      return this.calculateQuote(prod);
    });
  }

  public calculateQuote(product: Product): Quote {
    const levels = this.calculateLevels(product);
    const total = this.filteredRoster.reduce(
      (current, entry) => {
        return this.sumTotals(levels, entry, current);
      },
      new ResultTotal(0.0, 0.0),
    );
    const avg_member_cost = (total.total_cost - total.sponsor_cost) / parseFloat(this.groupSize);
    let maxMemberCost = 0.0;
    let minMemberCost = 100000000.0;
    const levelCosts = new Map<ContributionTierName, ContributionTierCost>();
    levels.forEach((val, k) => {
      const contribution_value = this.valueFromMapWithDefault(this.relContributions, k, 0.0);
      const contribution = val * contribution_value * 0.01;
      const mCost = val - contribution;
      levelCosts.set(k, {
        sponsor_cost: contribution,
        total_cost: val,
        member_cost: mCost,
      });
      if (mCost < minMemberCost) {
        minMemberCost = mCost;
      }
      if (mCost > maxMemberCost) {
        maxMemberCost = mCost;
      }
    });
    if (minMemberCost === 100000000.0) {
      minMemberCost = 0.0;
    }
    return new RosterQuote(
      product,
      total.total_cost,
      total.sponsor_cost,
      avg_member_cost,
      minMemberCost,
      maxMemberCost,
      levelCosts,
    );
  }

  private sumTotals(
    levels: Map<ContributionTierName, number>,
    entry: FilteredRelationshipRosterEntry,
    current_total: ResultTotal,
  ) {
    const cost = this.valueFromMapWithDefault(levels, entry.bucket, 0.0);
    const contribution_value = this.valueFromMapWithDefault(this.relContributions, entry.bucket, 0.0);
    const contribution = cost * contribution_value * 0.01;
    return current_total.add(new ResultTotal(cost, contribution));
  }

  private calculateLevels(product: Product) {
    const gs_factor = product.group_size_factor(this.groupSize);
    const pr_factor = product.participation_factor(this.participation);
    const sic_code_factor = product.sic_code_factor;
    const level_totals = this.initialBucket();
    const bucket_result = this.filteredRoster.reduce((current, re) => {
      return this.group_cost(product, re, sic_code_factor, gs_factor, pr_factor, current);
    }, level_totals);
    return bucket_result.toLevels(product);
  }

  private initialBucket() {
    const bucket_map = new Map<ContributionTierName, number>();
    bucket_map.set(ContributionTierName.EMPLOYEE_ONLY, 0.0);
    bucket_map.set(ContributionTierName.EMPLOYEE_AND_SPOUSE, 0.0);
    bucket_map.set(ContributionTierName.EMPLOYEE_AND_DEPENDENTS, 0.0);
    bucket_map.set(ContributionTierName.FAMILY, 0.0);
    return new BucketCount(bucket_map, 0.0);
  }

  private group_cost(
    product: Product,
    roster_entry: FilteredRelationshipRosterEntry,
    sic_factor: number,
    gs_factor: number,
    pr_factor: number,
    b_count: BucketCount,
  ) {
    const subscriber_cost =
      product.cost(this.coverageAge(this.startDate, roster_entry.dob).toFixed(0)) * sic_factor * gs_factor * pr_factor;
    let members_in_threshold = 0;
    const sorted_dependents = roster_entry.roster_dependents.sort((a, b) => {
      const a_age = this.coverageAge(this.startDate, a.dob);
      const b_age = this.coverageAge(this.startDate, b.dob);
      return b_age - a_age;
    });
    const total = sorted_dependents.reduce((current_total, rd) => {
      const age = this.coverageAge(this.startDate, rd.dob);
      let dependentCost = product.cost(age.toFixed(0)) * sic_factor * gs_factor * pr_factor;
      if (this.kind === 'health' && RelationshipDiscounts.relationship_discount) {
        if (
          age < RelationshipDiscounts.relationship_discount.relationship_threshold_age &&
          rd.relationship === RelationshipDiscounts.relationship_discount.relationship_kind
        ) {
          members_in_threshold = members_in_threshold + 1;
          if (members_in_threshold >= RelationshipDiscounts.relationship_discount.relationship_threshold) {
            dependentCost = 0.0;
          }
        }
      }
      return current_total + dependentCost;
    }, subscriber_cost);
    return b_count.add(roster_entry, total);
  }

  private coverageAge(coverageDate: Date, dob: Date | string) {
    const dobDate = typeof dob === 'string' ? new Date(dob) : dob;
    const year_diff = coverageDate.getFullYear() - dobDate.getFullYear();
    let offset = 0;
    if (dobDate.getMonth() > coverageDate.getMonth()) {
      offset = -1;
    } else if (dobDate.getMonth() === coverageDate.getMonth()) {
      offset = dobDate.getDate() > coverageDate.getDate() ? -1 : 0;
    }
    return year_diff + offset;
  }

  private valueFromMapWithDefault<K, V>(m: Map<K, V>, k: K, default_value: V) {
    const value = <V>m.get(k);
    if (value != null) {
      return value;
    }
    return default_value;
  }
}
