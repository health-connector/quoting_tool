import { Component, output, input, OnInit } from '@angular/core';

import { FormsModule } from '@angular/forms';

interface TreeItem {
  text: string;
  value: string;
  children?: TreeItem[];
  collapsed?: boolean;
}

@Component({
  selector: 'app-treeview-wrapper',
  template: `
    <div class="treeview">
      @if (showFilter()) {
        <div class="treeview-header">
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
      }
      <div class="treeview-items">
        @for (item of filteredItems; track item.value) {
          <div class="treeview-item">
            <div class="item-content">
              @if (item.children?.length) {
                <i
                  class="fa"
                  [class.fa-caret-right]="item.collapsed"
                  [class.fa-caret-down]="!item.collapsed"
                  (click)="toggleCollapse(item)"
                ></i>
              }
              <span class="item-text" (click)="select(item)">{{ item.text }}</span>
            </div>
            @if (item.children?.length && !item.collapsed) {
              <div class="item-children">
                @for (child of item.children; track child.value) {
                  <div class="treeview-item">
                    <div class="item-content">
                      @if (child.children?.length) {
                        <i
                          class="fa"
                          [class.fa-caret-right]="child.collapsed"
                          [class.fa-caret-down]="!child.collapsed"
                          (click)="toggleCollapse(child)"
                        ></i>
                      }
                      <span class="item-text" (click)="select(child)">{{ child.text }}</span>
                    </div>
                    @if (child.children?.length && !child.collapsed) {
                      <div class="item-children">
                        @for (grandChild of child.children; track grandChild.value) {
                          <div class="treeview-item">
                            <div class="item-content">
                              @if (grandChild.children?.length) {
                                <i
                                  class="fa"
                                  [class.fa-caret-right]="grandChild.collapsed"
                                  [class.fa-caret-down]="!grandChild.collapsed"
                                  (click)="toggleCollapse(grandChild)"
                                ></i>
                              }
                              <span class="item-text" (click)="select(grandChild)">{{ grandChild.text }}</span>
                            </div>
                            @if (grandChild.children?.length && !grandChild.collapsed) {
                              <div class="item-children">
                                @for (greatGrandChild of grandChild.children; track greatGrandChild.value) {
                                  <div class="treeview-item">
                                    <div class="item-content">
                                      <span class="item-text" (click)="select(greatGrandChild)">{{
                                        greatGrandChild.text
                                      }}</span>
                                    </div>
                                  </div>
                                }
                              </div>
                            }
                          </div>
                        }
                      </div>
                    }
                  </div>
                }
              </div>
            }
          </div>
        }
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
    `,
  ],
  imports: [FormsModule],
})
export class TreeviewWrapperComponent implements OnInit {
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
    const filteredItems: TreeItem[] = [];

    for (const item of items) {
      const matches = item.text.toLowerCase().includes(searchText);

      if (item.children?.length) {
        const filteredChildren = this.filterTreeItems(item.children, searchText);

        if (matches || filteredChildren.length > 0) {
          // Create a new item with filtered children and expand it to show matches
          const clonedItem: TreeItem = {
            ...item,
            children: filteredChildren.length > 0 ? filteredChildren : item.children,
            collapsed: filteredChildren.length > 0 ? false : item.collapsed, // Auto-expand if children match
          };
          filteredItems.push(clonedItem);
        }
      } else if (matches) {
        // Leaf node that matches
        filteredItems.push({ ...item });
      }
    }

    return filteredItems;
  }
}
