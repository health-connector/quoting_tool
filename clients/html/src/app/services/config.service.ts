import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { lastValueFrom } from 'rxjs';

//defines the shape of config.json, which is loaded at runtime and contains environment-specific configuration such as API URLs
interface AppConfig {
  envApi: string;
  cataract_api: string;
}

@Injectable({
  providedIn: 'root',
})
export class ConfigService {
  private http = inject(HttpClient);
  private configData: AppConfig | null = null;

  loadConfig(): Promise<void> {
    // Resolves correctly in both dev and prod:
    // - dev:  <base href="/get-a-quote">  → /assets/config.json
    // - prod: <base href="/get-a-quote/"> → /get-a-quote/assets/config.json
    const configUrl = new URL('assets/config.json', document.baseURI).toString();
    return lastValueFrom(this.http.get<AppConfig>(configUrl))
      .then((data) => {
        this.configData = data;
      })
      .catch((err) => {
        console.error('Failed to load app configuration', err);
      });
  }

  get envApi(): string {
    return this.configData?.envApi ?? '';
  }

  get cataractApi(): string {
    return this.configData?.cataract_api ?? '';
  }
}
