export class Client {
  public config: Configuration;

  constructor(apiKeyOrConfig?: string | Configuration);

  public notify(
    error: Error,
    beforeSendCallback?: BeforeSend,
    blocking?: boolean,
    postSendCallback?: (sent: boolean) => void,
  ): void;

  public setUser(id?: string, name?: string, email?: string): void;

  public clearUser(): void;

  public startSession(): void;

  public stopSession(): void;

  public resumeSession(): void;

  public enableConsoleBreadcrumbs(): void;

  public disableConsoleBreadCrumbs(): void;

  public leaveBreadcrumb(name: string, metadata?: IMetadata | string): void;
}

export class Configuration {
  public version: string;
  public apiKey?: string;
  public delivery: StandardDelivery;
  public beforeSendCallbacks: BeforeSend[];
  public notifyReleaseStages?: string[];
  public releaseStage?: string;
  public appVersion?: string;
  public codeBundleId?: string;
  public autoNotify: boolean;
  public handlePromiseRejections: boolean;
  public autoCaptureSessions: boolean;
  public automaticallyCollectBreadcrumbs: boolean;
  public consoleBreadcrumbsEnabled: boolean;

  constructor(apiKey?: string);

  public shouldNotify(): boolean;

  public registerBeforeSendCallback(callback: BeforeSend): void;

  public unregisterBeforeSendCallback(
    callback: BeforeSend,
  ): void;

  public clearBeforeSendCallbacks(): void;

  public toJSON(): any;
}

type BeforeSend = (report: Report) => boolean | void;

export class StandardDelivery {
  public endpoint: string;
  public sessionsEndpoint: string;

  constructor(endpoint: string, sessionsEndpoint: string);
}

export interface IMetadata {
  type?:
    | "error"
    | "log"
    | "navigation"
    | "process"
    | "request"
    | "state"
    | "user"
    | "manual";
  [key: string]: IMetadataValue | string | number | boolean | undefined;
}

export interface IMetadataValue {
  [key: string]: string | number | boolean | undefined;
}

export class Report {
  public apiKey: string;
  public errorClass: string;
  public errorMessage: string;
  public context?: string;
  public groupingHash?: string;
  public metadata: IMetadata;
  public severity: "warning" | "error" | "info";
  public stacktrace: string;
  public user: any;

  constructor(apiKey: string, error: Error);

  public addMetadata(
    section: string,
    key: string,
    value: number | string | boolean,
  ): void;

  public toJSON(): any;
}
