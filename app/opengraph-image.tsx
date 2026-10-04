import { ImageResponse } from "next/og";

export const alt = "Clubmates — Find Your People. Own the Night.";
export const size = { width: 1200, height: 630 };
export const contentType = "image/png";

export default function OpenGraphImage() {
  return new ImageResponse(
    (
      <div
        style={{
          width: "100%",
          height: "100%",
          display: "flex",
          flexDirection: "column",
          justifyContent: "flex-end",
          background: "#FFFEFD",
          padding: "80px",
        }}
      >
        <div
          style={{
            fontSize: 22,
            letterSpacing: 6,
            color: "#67295F",
            fontWeight: 600,
          }}
        >
          CLUBMATES
        </div>
        <div
          style={{
            marginTop: 28,
            fontSize: 78,
            lineHeight: 1.02,
            color: "#1A1A1A",
            fontWeight: 500,
            maxWidth: 920,
          }}
        >
          Find Your People. Own the Night.
        </div>
        <div style={{ marginTop: 28, fontSize: 28, color: "#484848" }}>
          Find people heading out and make a plan together.
        </div>
      </div>
    ),
    { ...size },
  );
}
