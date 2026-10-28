import { createHash, randomUUID } from "node:crypto";
import {
  Inject,
  Injectable,
  Logger,
  type OnModuleDestroy,
  type OnModuleInit,
} from "@nestjs/common";
import { Kafka, Partitioners, type Producer } from "kafkajs";
import { CONFIG, type Config } from "../config/config";
import { ContractService } from "../contract/contract.service";
import { StorageService } from "../storage/storage.service";
import { UPLOADS_TOPIC } from "./topics";

/** `<major>.<minor>` (envelope.schema.json); consumers reject another major. */
export const ENVELOPE_VERSION = "1.0";

/**
 * Publishes validated envelopes (api/common/contract/envelope.schema.json) on
 * the CueLABS shared bus. Every product can read its lanes, so the payload is
 * written to tmp/claims/ and the message carries only the pointer
 * (docs/system-design.md §5.3; the bucket's 24 h tmp/ lifecycle removes it).
 */
@Injectable()
export class KafkaProducerService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(KafkaProducerService.name);
  private readonly producer: Producer;
  private connected = false;

  constructor(
    @Inject(CONFIG) config: Config,
    private readonly contract: ContractService,
    private readonly storage: StorageService,
  ) {
    const { kafka } = config;
    const kafkaClient = new Kafka({
      clientId: "apparule-api-uploads",
      brokers: kafka.brokers,
      ...(kafka.username
        ? {
            // Aiven: SASL/SCRAM over TLS, the product's own Kafka user (X-11).
            ssl: kafka.sslCa ? { ca: [kafka.sslCa] } : true,
            sasl: {
              mechanism: "scram-sha-256" as const,
              username: kafka.username,
              password: kafka.password,
            },
          }
        : {}),
    });
    this.producer = kafkaClient.producer({
      idempotent: true,
      maxInFlightRequests: 1,
      allowAutoTopicCreation: false,
      // Keyed partitioning (murmur2). Each topic has one producing service,
      // so the clients' differing hash functions never split a key.
      createPartitioner: Partitioners.DefaultPartitioner,
    });
    this.producer.on("producer.disconnect", () => (this.connected = false));
  }

  async onModuleInit(): Promise<void> {
    // Don't block startup on Kafka: /ready reports it, and send() connects.
    this.connect().catch((error: Error) =>
      this.logger.warn({
        message: "kafka not reachable yet",
        error: error.message,
      }),
    );
  }

  async onModuleDestroy(): Promise<void> {
    await this.producer.disconnect();
  }

  get isConnected(): boolean {
    return this.connected;
  }

  /** Every upload is a request to common, so it gets its own request_id. */
  async send(
    event: string,
    key: string,
    data: object,
    requestId: string = randomUUID(),
  ): Promise<void> {
    this.contract.validateData(event, data);
    const id = randomUUID();
    const body = Buffer.from(JSON.stringify(data));
    const dataRef = await this.storage.store(
      `${this.storage.prefix}/tmp/claims/${id}.json`,
      body,
      "application/json",
      createHash("sha256").update(body).digest("hex"),
    );
    const envelope = {
      type: event,
      version: ENVELOPE_VERSION,
      id,
      produced_at: new Date().toISOString(),
      request_id: requestId,
      data_ref: dataRef,
    };
    this.contract.validateEnvelope(envelope);
    await this.connect();
    await this.producer.send({
      topic: UPLOADS_TOPIC,
      acks: -1,
      messages: [{ key, value: JSON.stringify(envelope) }],
    });
  }

  private async connect(): Promise<void> {
    if (this.connected) return;
    await this.producer.connect();
    this.connected = true;
  }
}
