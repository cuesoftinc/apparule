// A6 For designers — "Post outfits, get commissioned, get paid" with the
// earnings composition (canvas 186:131–186:150): EarningsSummary + two
// TransactionRows carrying the canvas demo figures.
import {
  EarningsSummary,
  TransactionRow,
} from "@/components/ui/EarningsSummary";
import { designerEarningsDemo } from "@/controllers/home-demo";

export function DesignersSection() {
  return (
    <section
      id="designers"
      aria-labelledby="designers-heading"
      className="mx-auto w-full max-w-[1128px] scroll-mt-20 px-6 py-12"
    >
      <div className="flex flex-col items-start gap-10 md:flex-row md:items-center md:gap-16">
        <div className="max-w-[480px] flex-1">
          <h2
            id="designers-heading"
            className="text-title-lg font-bold text-text"
          >
            Post outfits, get commissioned, get paid
          </h2>
          <p className="mt-4 text-body-lg text-text-2">
            Every request arrives with the customer&apos;s measurement snapshot.
            Quote, sew, ship — funds sit in escrow and release on delivery
            confirmation.
          </p>
        </div>
        <div className="w-full max-w-[400px] shrink-0">
          <EarningsSummary earnings={designerEarningsDemo.earnings} />
          <div className="mt-2">
            {designerEarningsDemo.transactions.map((t) => (
              <TransactionRow
                key={t.entry.id}
                entry={t.entry}
                label={t.label}
              />
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}
