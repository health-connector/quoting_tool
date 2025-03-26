import { Component, output, input } from '@angular/core';
import { NgIf, NgTemplateOutlet, NgFor } from '@angular/common';
import { FormsModule } from '@angular/forms';

interface TreeItem {
  text: string;
  value: any;
  children?: TreeItem[];
  collapsed?: boolean;
}

@Component({
  selector: 'app-treeview-wrapper',

  template: `
    <div class="treeview">
      <div class="treeview-header" *ngIf="showFilter()">
        <div class="form-group">
          <input
            type="text"
            class="form-control"
            placeholder="Search..."
            [(ngModel)]="filterText"
            (ngModelChange)="onFilterTextChange()"
          />
        </div>
      </div>
      <div class="treeview-items">
        <ng-container *ngFor="let item of filteredItems">
          <div class="treeview-item">
            <div class="item-content">
              <i
                *ngIf="item.children?.length"
                class="fa"
                [class.fa-caret-right]="item.collapsed"
                [class.fa-caret-down]="!item.collapsed"
                (click)="toggleCollapse(item)"
              ></i>
              <span class="item-text" (click)="select(item)">{{ item.text }}</span>
            </div>
            <div class="item-children" *ngIf="item.children?.length && !item.collapsed">
              <ng-container *ngFor="let child of item.children">
                <div class="treeview-item">
                  <div class="item-content">
                    <i
                      *ngIf="child.children?.length"
                      class="fa"
                      [class.fa-caret-right]="child.collapsed"
                      [class.fa-caret-down]="!child.collapsed"
                      (click)="toggleCollapse(child)"
                    ></i>
                    <span class="item-text" (click)="select(child)">{{ child.text }}</span>
                  </div>
                  <div class="item-children" *ngIf="child.children?.length && !child.collapsed">
                    <ng-container *ngFor="let grandChild of child.children">
                      <div class="treeview-item">
                        <div class="item-content">
                          <span class="item-text" (click)="select(grandChild)">{{ grandChild.text }}</span>
                        </div>
                      </div>
                    </ng-container>
                  </div>
                </div>
              </ng-container>
            </div>
          </div>
        </ng-container>
      </div>
    </div>
  `,
  styles: [
    `
      .treeview {
        font-family: Arial, sans-serif;
      }
      .treeview-header {
        margin-bottom: 1rem;
      }
      .treeview-items {
        max-height: 400px;
        overflow-y: auto;
      }
      .treeview-item {
        margin: 0.25rem 0;
      }
      .item-content {
        display: flex;
        align-items: center;
        cursor: pointer;
      }
      .item-content i {
        margin-right: 0.5rem;
        width: 1rem;
        text-align: center;
      }
      .item-text {
        flex: 1;
      }
      .item-children {
        margin-left: 1.5rem;
      }
    `
  ],
  standalone: true,
  imports: [NgIf, NgTemplateOutlet, NgFor, FormsModule]
})
export class TreeviewWrapperComponent {
  items = input<TreeItem[]>([]);
  showFilter = input<boolean>(true);
  valueChange = output<TreeItem>();

  filterText: string = '';
  filteredItems: TreeItem[] = [];

  ngOnInit() {
    this.filteredItems = this.items();
  }

  toggleCollapse(item: TreeItem) {
    item.collapsed = !item.collapsed;
  }

  select(item: TreeItem) {
    if (!item.children?.length) {
      this.valueChange.emit(item);
    }
  }

  onFilterTextChange() {
    if (!this.filterText) {
      this.filteredItems = [...this.items()];
      return;
    }

    const searchText = this.filterText.toLowerCase();
    this.filteredItems = this.filterTreeItems(this.items(), searchText);
  }

  private filterTreeItems(items: TreeItem[], searchText: string): TreeItem[] {
    return items.filter((item) => {
      const matches = item.text.toLowerCase().includes(searchText);
      if (matches) return true;

      if (item.children?.length) {
        const filteredChildren = this.filterTreeItems(item.children, searchText);
        if (filteredChildren.length) {
          const clonedItem = { ...item, children: filteredChildren };
          return true;
        }
      }

      return false;
    });
  }
}
