import { Component, OnInit } from '@angular/core';
import { SelectedSicService } from '../services/selected-sic.service';
import { TreeviewItem, TreeviewConfig, TreeviewModule } from 'ngx-treeview';
import sicCodes from '../../data/sicCodes.json';
import { FormsModule } from '@angular/forms';
import { NgIf } from '@angular/common';

@Component({
    selector: 'app-dropdown-treeview-select',
    templateUrl: './dropdown-treeview-select.component.html',
    styleUrls: ['./dropdown-treeview-select.component.css'],
    standalone: true,
    imports: [NgIf, FormsModule, TreeviewModule]
})
export class DropdownTreeviewSelectComponent implements OnInit {
  items: TreeviewItem[] = [];
  sicCodes: any[] = sicCodes;

  config: TreeviewConfig = TreeviewConfig.create({
    hasFilter: true,
    hasCollapseExpand: false
  });

  constructor(private selectedSicService: SelectedSicService) { }

  ngOnInit() {
    this.items = this.buildSicTree();
  }

  onValueChange(value: number) {
    console.log('Value Change:', value);
  }

  select(item: TreeviewItem) {
    if (!item.children) {
      this.selectItem(item);
    }
  }

  private selectItem(item: TreeviewItem) {
    this.selectedSicService.changeMessage(item);
  }

  private buildSicTree(): TreeviewItem[] {
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
      if (!majorGroupLabels.some(mgl => mgl.text === sic['MajorGroup_Label'])) {
        majorGroupLabels.push({
          key: sic['Division_Label'],
          text: sic['MajorGroup_Label'],
          code: sic['MajorGroup_Code'].split(' ')[2],
          collapsed: true
        });
      }

      // Collect unique Industry Group Labels
      if (!industryGroupLabels.some(igl => igl.text === sic['IndustryGroup_Label'])) {
        industryGroupLabels.push({
          key: sic['MajorGroup_Label'],
          text: sic['IndustryGroup_Label'],
          value: sic['IndustryGroup_Code'].split(' ')[2],
          collapsed: true
        });
      }

      // Collect unique Standard Industry Codes
      if (!standardIndustryCodes.some(sicCode => sicCode.value === sic['StandardIndustryCode_Code'])) {
        standardIndustryCodes.push({
          key: sic['IndustryGroup_Label'],
          text: sic['StandardIndustryCode_Full'],
          value: sic['StandardIndustryCode_Code'],
          collapsed: true
        });
      }
    });

    // Build tree structure
    const availableItems: TreeviewItem[] = [];

    divisionLabels.forEach((divisionLabel, index) => {
      const divisionNode = {
        text: divisionLabel,
        value: index,
        collapsed: true,
        children: []
      };

      // Add Major Group Labels
      divisionNode.children = majorGroupLabels
        .filter(mgl => mgl.key === divisionLabel)
        .map(mgl => ({
          ...mgl,
          children: []
        }));

      // Add Industry Group Labels
      divisionNode.children.forEach(child => {
        child.children = industryGroupLabels
          .filter(igl => igl.key === child.text)
          .map(igl => ({
            ...igl,
            children: []
          }));

        // Add Standard Industry Codes
        child.children.forEach(kid => {
          kid.children = standardIndustryCodes.filter(sic => sic.key === kid.text);
        });
      });

      availableItems.push(new TreeviewItem(divisionNode));
    });

    return availableItems;
  }
}
