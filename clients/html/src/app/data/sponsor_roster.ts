import { ContributionRelationship } from '../config/contribution_relationship';

export interface RosterDependent {
  dob: Date;
  relationship: ContributionRelationship;
}

export interface RosterEntry {
  // dob: Date;
  dob: string | Date; // Ensure dob is here if needed
  roster_dependents: Array<RosterDependent>;
  will_enroll: boolean;
  coverageKind: string; // Add this line
  dependents: Array<{ dob: string | Date; relationship: string }>; // Add or update this line
}
