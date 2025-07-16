import { Component, OnInit, inject } from '@angular/core';
import { SelectedSicService } from '../../services/selected-sic.service';
import sicCodes from '../../../data/sicCodes.json';
import { FormsModule } from '@angular/forms';
import { TreeviewWrapperComponent } from '../treeview-wrapper/treeview-wrapper.component';

// Define the structure for SIC code entries imported from JSON
interface SicCodeEntry {
  Division_Label: string;
  MajorGroup_Label: string;
  MajorGroup_Code: string;
  IndustryGroup_Label: string;
  IndustryGroup_Code: string;
  StandardIndustryCode_Code: number;
  StandardIndustryCode_Full: string;
}

interface TreeItem {
  text: string;
  value: string;
  children?: TreeItem[];
  collapsed?: boolean;
}

@Component({
  selector: 'app-dropdown-treeview-select',
  template: ` <app-treeview-wrapper [items]="items" [showFilter]="true" (valueChange)="select($event)" /> `,
  imports: [FormsModule, TreeviewWrapperComponent],
})
export class DropdownTreeviewSelectComponent implements OnInit {
  private selectedSicService = inject(SelectedSicService);
  items: TreeItem[] = [];
  sicCodes: SicCodeEntry[] = sicCodes; // Use the defined interface

  ngOnInit() {
    this.items = this.buildSicTree();
  }

  select(item: TreeItem) {
    if (!item.children) {
      this.selectedSicService.changeMessage(item);
    }
  }

  private buildSicTree(): TreeItem[] {
    const divisionLabels: string[] = [];
    const majorGroupLabels: { key: string; text: string; code: string; collapsed: boolean }[] = [];
    const industryGroupLabels: { key: string; text: string; value: string; collapsed: boolean }[] = [];
    const standardIndustryCodes: { key: string; text: string; value: string; collapsed: boolean }[] = [];

    // Process SIC codes
    this.sicCodes.forEach((sic) => {
      // Collect unique Division Labels
      if (!divisionLabels.includes(sic['Division_Label'])) {
        divisionLabels.push(sic['Division_Label']);
      }

      // Collect unique Major Group Labels
      if (!majorGroupLabels.some((mgl) => mgl.text === sic['MajorGroup_Label'])) {
        majorGroupLabels.push({
          key: sic['Division_Label'],
          text: sic['MajorGroup_Label'],
          code: sic['MajorGroup_Code'].split(' ')[2],
          collapsed: true,
        });
      }

      // Collect unique Industry Group Labels
      if (!industryGroupLabels.some((igl) => igl.text === sic['IndustryGroup_Label'])) {
        industryGroupLabels.push({
          key: sic['MajorGroup_Label'],
          text: sic['IndustryGroup_Label'],
          value: sic['IndustryGroup_Code'].split(' ')[2],
          collapsed: true,
        });
      }

      // Collect unique Standard Industry Codes
      if (!standardIndustryCodes.some((sicCode) => sicCode.value === String(sic['StandardIndustryCode_Code']))) {
        standardIndustryCodes.push({
          key: sic['IndustryGroup_Label'],
          text: sic['StandardIndustryCode_Full'],
          value: String(sic['StandardIndustryCode_Code']),
          collapsed: true,
        });
      }
    });

    // Build tree structure
    const availableItems: TreeItem[] = [];

    divisionLabels.forEach((divisionLabel, index) => {
      const divisionNode: TreeItem = {
        text: divisionLabel,
        value: String(index),
        collapsed: true,
        children: [],
      };

      // Add Major Group Labels
      divisionNode.children = majorGroupLabels
        .filter((mgl) => mgl.key === divisionLabel)
        .map((mgl) => ({
          ...mgl,
          value: mgl.code,
          children: [],
        }));

      // Add Industry Group Labels
      divisionNode.children.forEach((child) => {
        child.children = industryGroupLabels
          .filter((igl) => igl.key === child.text)
          .map((igl) => ({
            ...igl,
            value: igl.value,
            children: [],
          }));

        // Add Standard Industry Codes
        child.children.forEach((kid) => {
          kid.children = standardIndustryCodes.filter((sic) => sic.key === kid.text);
        });
      });

      availableItems.push(divisionNode);
    });

    return availableItems;
  }
}
